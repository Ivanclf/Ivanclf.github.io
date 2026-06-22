---
title: 常见业务模型 - LLM 与传统 AI 的设计模式实现
date: 2026-01-27 16:14:21
tags: [java]
category: 业务
---

## ASR 语音识别

在一个后端程序中，Java 服务器代码并不提供语音识别功能，其功能往往通过调用第三方接口实现。常见的识别 API 提供商有阿里云、百度、字节、科大讯飞等。

### 音频文件传入

一般而言，传入有两种方式：
- 通过 HTTP POST 请求，获取音频数据. 需要传入的参数为已经编码好（如 base64 编码）的音频文件
- 直接从本地上传。通过 `MultipartFile` 对象传输文件本身。

为了兼容两种格式的传入，传输的 DTO 应该包含录音文件 url、来源、租户 id、渠道（不能为空）、会话 id、坐席 id、接口指向、回调 url、录音文件名、语速、开始时间、结束时间、录音时长、声道（单声道为 `mono`，双声道为 `stereo`），而本地传入应该多加一个 `MultipartFile` 对象。

### 多厂商适配 (工厂模式 + 策略模式)

#### 工厂模式核心设计

对于不同的 API，我们理应实现多个不同的实现类，在某个 API 存在时则加载对应的实现类。如果工厂类找不到对应的实现类，则直接报错。

不同的实现类，通过多态实现不同 Impl 类的动态加载。

```java
// Spring 自动将所有的 AsrRequestService 的实现类注入到这个 map 中
private final Map<String, AsrRequestService> asrServices;

// 根据厂商名字获取对应的服务
private AsrRequestService transcribe(String vendor) {
    return asrServices.getOrDefault(vendor, null);
}

// 使用
AsrRequestService service = transcribe(request.getVendor());
if (service == null) {
    log.error("不支持的厂商: {}", request.getVendor());
    return new AsrResponse("-1", "不支持的厂商: " + request.getVendor());
}
```

#### 条件加载实现类

使用以下注解, 以期实现通过配置文件来控制是否加载对应的厂商实现.

```java
@ConditionalOnProperty(
    prefix = "asr.vendors",
    name = "enabled",
    havingValue = "xunfei"
)
```

如果传入的参数为一个，那么就是 HTTP 传输，若为两个（多了 `MultipartFile`）就是本地传输。然后调用对应的 `transcribe` 方法。

#### 标准流程

1. 顶层接口: 定义 `transcribe` 方法, 适配 HTTP/本地两种文件
2. 抽象类: 实现通用流程
3. 厂商各自的实现类, 继承抽象类, 重写厂商的特有逻辑
4. 前置处理, 将会话信息存入 redis 做幂等/状态管理

### 回调

接收到 ASR 服务后，外部还会给服务器发一个回调数据。通过与上述实现类对应的回调实现类，可以获取 ASR 的响应结果。

## AI 接口

此处的大部分代码是这个工厂模式的更激进的做法，同时尽量不动原有的会话管理功能。在这个实现中，所有的模型接口均只由一个 Controller 接收。不同的接口应该用于定义返回的json类型，以适应不同的智能体需求。而要求的 LLM 服务提供商则直接放在参数中。

### 统一接口实现

```java
@RestController
@Slf4j
@RequestMapping(value = "/v1/llm")
@Tag(name = "LLM统一接口")
public class LlmController {

    @Autowired
    private LlmServiceFactory llmServiceFactory;

    /**
     * 1. 发送消息到指定模型
     *
     * @param modelName 模型名称
     * @param message 消息内容，JSON格式，包含message字段和可选的sessionId字段
     * @return ApiResponse<JSONObject> 响应结果
     */
    @Operation(description = "发送消息到指定模型")
    @PostMapping(value = "/sendMessage/{modelName}")
    public ApiResponse<JSONObject> sendMessage(
            @Parameter(description = "模型名称") @PathVariable String modelName,
            @RequestBody @Validated JSONObject message) {
        try {

            LlmService llmService = llmServiceFactory.getLlmService(modelName);
            JSONObject result = llmService.sendMessage(modelName, message);

            if (result != null && !result.containsKey("msg")) {
                return ApiResponse.data(200, result, "消息发送成功");
            } else {
                String errorMsg = result != null ? result.getString("msg") : "未知错误";
                return ApiResponse.fail("消息发送失败: " + errorMsg);
            }
        } catch (Exception e) {
            return ApiResponse.fail("消息发送异常: " + e.getMessage());
        }
    }

    /**
     * 2. 获取指定模型的会话历史信息
     *
     * @param modelName 模型名称
     * @param sessionId 会话ID
     * @param lastNum 获取最后几轮对话，默认5轮
     * @return ApiResponse<JSONObject> 会话历史信息
     */
    @Operation(description = "获取指定模型的会话历史信息")
    @GetMapping(value = "/session/{modelName}/{sessionId}")
    public ApiResponse<JSONObject> getSessionInfo(
            @Parameter(description = "模型名称") @PathVariable String modelName,
            @Parameter(description = "会话ID") @PathVariable String sessionId,
            @Parameter(description = "获取最后几轮对话") @RequestParam(defaultValue = "5") int lastNum) {
        try {
            JSONObject result = new JSONObject();
            result.put("modelName", modelName);
            result.put("sessionId", sessionId);
            result.put("lastNum", lastNum);
            result.put("message", "会话信息获取功能需要配合具体模型配置使用");

            return ApiResponse.data(200, result, "会话信息获取成功");
        } catch (Exception e) {
            return ApiResponse.fail("获取会话信息异常: " + e.getMessage());
        }
    }
}
```

工厂模式实现

此处的请求转发到统一的工厂类中。工厂类按照传入的 modelName 参数，去匹配是否存在这样的 Impl 类，没有就报错，有就去找对应的实现。

```java
@Component
@Slf4j
public class LlmServiceFactory {

    private final Map<String, LlmService> llmServices;

    @Autowired
    public LlmServiceFactory(Map<String, LlmService> llmServices) {
        this.llmServices = llmServices;
    }

    /**
     * 根据服务类型获取对应的LLM服务
     * @param serviceType 服务类型 (deepseek, doubao, dify等)
     * @return LlmService实现
     */
    public LlmService getLlmService(String serviceType) {
        return service = llmServices.getOrDefault(serviceType + "LlmServiceImpl", getDefaultService());
    }

    /**
     * 获取默认的LLM服务
     * @return 默认的LlmService实现 (deepseek)
     */
    public LlmService getDefaultLlmService() {
        LlmService defaultService = llmServices.get("deepseekLlmServiceImpl");
        if (defaultService == null) {
            if (llmServices.isEmpty()) {
                throw new IllegalStateException("没有可用的LLM服务实现");
            }
            defaultService = llmServices.values().iterator().next();
        }
        return defaultService;
    }
}
```

### 抽象类实现 (可选)

在具体实现前，先使用一个抽象类去定义一个公约数。因为所有的实现类都需要 apiKey、name 等信息，以及相关的 Getter 等公共方法。放抽象类可以节省代码量。**但是这个抽象类不要给 Spring 管理**。

```java
@Slf4j
public abstract class AbstractLlmServiceImpl implements LlmService {

	protected String apiKey;

	protected String name;

	protected String url;

	protected int sessionTimeout;

	protected StringRedisTemplate redisTemplate;

	@Override
	public void init() {}

	@Override
	public JSONObject sendMessage(AiParams originMessage) {
		return null;
	}

    // 公共方法
}
```

#### 厂商实现

然后对于一个 Impl 的具体实现（此处以 Deepseek 为例），最理想的状态就是在查询到有对应配置后才开始加载，否则不加载

```java
@Service
@Slf4j
@ConditionalOnProperty(prefix = "llm.models.deepseek", name = "enabled", havingValue = "true")
public class DeepseekLlmServiceImpl implements AbstractLlmService {

	private static final String REDIS_SESSION_PREFIX = "thdai:deepseek:chat:session:";

	private DeepSeekService deepSeekService;

	public DeepseekLlmServiceImpl(@Autowired StringRedisTemplate redisTemplate,
								  @Value("${llm.models.deepseek.apiKey}") String apiKey,
								  @Value("${llm.models.deepseek.name}") String name,
								  @Value("${llm.models.deepseek.url}") String url,
								  @Value("${llm.models.deepseek.sessionTimeout}") int sessionTimeout) {
		this.redisTemplate = redisTemplate;
		this.apiKey = apiKey;
		this.name = name;
		this.url = url;
		this.sessionTimeout = sessionTimeout;
	}

	@PostConstruct
	public void init() {
		AIConfig config = new AIConfigBuilder(ModelName.DEEPSEEK.getValue())
			.setApiKey(apiKey)
			.setModel(name)
			.setApiUrl(url)
			.build();
		deepSeekService = AIServiceFactory.getAIService(config, DeepSeekService.class);
	}

    // 业务代码
}
```

#### AOP 负责公共逻辑

而对于会话管理功能，其 redis 键依赖各个子类的实现，父类不太好抽象，因此使用 aop 切面反射出对应的值。在新建切面时，首先需要定义切面覆盖到的方法

```java
@Pointcut("execution(* com.example.llm.LlmService.sendMessage(com.example.demo.entity.llm.aiParam.AiParams))")
public void LlmServicePointCut() {}
```

一般使用 `@Around` 注解的多。分为两个切面，一个切面用于会话管理，顺序较为前面，另一个切面用于返回值处理，顺序较后。因为会话管理不同的服务可能不一样，因此此处使用注解来动态分配，而返回值处理是通过参数来实现的，因此全部的 Service 都要被代理。

#### 会话管理切面

注解的声明方式。当然还可以在这里面放一些参数

```java
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface EnableCommonLlmSessionManage {
}
```

会话管理切面核心部分

```java
/**
 * 通用会话管理切面
 */
@Pointcut("@annotation(com.example.llm.annotation.EnableCommonLlmSessionManage)")
public void LlmServiceCommonSessionPointCut() {}

/**
 * 该切面用于处理大模型的会话管理
 * @param joinPoint
 */
@Around("LlmServiceCommonSessionPointCut()")
public Object aroundAdvice(ProceedingJoinPoint joinPoint) {
    AiParams originalMessage = null;
    String sessionId = null;
    String redisSessionPrefix = null;

    Object[] args = null;
    try {
        // 获取Service的参数
        args = joinPoint.getArgs();
        if (args.length > 0 && args[0] instanceof AiParams) {
            originalMessage = (AiParams) args[0];

            Object target = joinPoint.getTarget();
            if (target instanceof LlmService llmService) {
                redisSessionPrefix = llmService.getRedisSessionPrefix();
            }

            // 检查AiParams中是否有sessionId
            // ...

            // 获取上下文
        }
    } catch (Exception e) {
        log.error("beforeAdvice error: {}", originalMessage, e);
    }

    // 执行目标方法
    Object result = null;
    try {
        result = joinPoint.proceed(args);
    } catch (Throwable e) {
        log.error("执行方法时出错");
    }

    try {
        // 参数校验

        AiParams aiParams = (AiParams) args[0];
        JSONObject jsonObject = (JSONObject) result;

        // 获取会话信息用于保存
        int sessionTimeout = 180; // 默认值

        // 获取sessionId并保存到redis
        // ...
    } catch (Exception e) {
        log.error("afterAdvice error，{}", e.getMessage(), e);
    }

    return result;
}
```

#### 返回值处理切面

返回值处理接口直接用 switch 就可以了

```java
@Aspect
@Component
@Slf4j
@Order(2)
public class LlmReturnProceedAspect {

	/**
	 * 返回值处理切面
	 */
	@Pointcut("execution(* com.example.llm.service.llm.LlmService.sendMessage(com.example.llm.entity.llm.aiParam.AiParams))")
	public void LlmServiceReturnProceedPointcut() {}

	@Around("LlmServiceReturnProceedPointcut()")
	public Object aroundAdvice(ProceedingJoinPoint joinPoint) throws Throwable {
		Object result = joinPoint.proceed();

		try {
			Object[] args = joinPoint.getArgs();
			if (args.length > 0 && args[0] instanceof AiParams aiParams && result instanceof JSONObject jsonObject) {

				switch (aiParams.getResponseType()) {
					case ORIGINAL -> {
                        // 不做处理
					}
					case QMS -> {
                        // 处理逻辑
					}
                    // ...
					default -> throw new RuntimeException("参数错误");
				}
			}
		} catch (Exception e) {
			log.error("LlmReturnProceedAspect error: {}", e.getMessage(), e);
		}

		return result;
	}
}
```

这就是一条配置化代码的实现流程。

### 总结

在完整的实现流程中，体现了以下的设计模式
- 策略模式
    定义统一的接口和不同的实现类，即通过工厂，根据模型名称动态选择具体实现，从而支持运行时切换不同的 LLM 服务提供商。
- 工厂模式
    通过统一的工厂类，负责创建和管理不同的 LLM 示例。通过 Spring 的依赖注入，自动收集所有的 LlmService 实现到 Map 中。
- 装饰器模式
    AOP 切面作为装饰器，为核心的调接口服务提供会话管理功能，从而实现短时间的聊天记录保存功能。