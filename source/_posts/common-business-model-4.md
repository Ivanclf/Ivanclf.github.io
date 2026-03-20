---
title: 常见业务模型 - 文字识别
date: 2026-02-09 10:13:08
tags: [java]
category: 业务
---

文字识别分为两大领域：**OCR** 和 **ICR**。OCR 是光学字符识别，用于识别印刷体文字；ICR 是智能字符识别，用于识别手写体文字。在此处的实现中，主要使用 TextIn 中提供的 API。

## OCR

微信的截图识别文字、还有 Deepseek 发图片时的文字解析，用的都是 OCR 技术。该技术接收图片文件，识别图片中的印刷体内容，最后返回分割好的 OCR 识别文本数组。其分割依据一般按照自然文本块或自然文本（如一行、一段等）。使用的实体类中包含返回的文本、置信度得分、文本类型、位置、是否手写这些信息。

然后向 TextIn API 发送信息

```java
// 初始化结果列表
List<OcrResponseVO> ocrResponseVOs = new ArrayList<>();

// 构建请求头，添加合合信息API认证信息
HttpHeaders headers = new HttpHeaders();
headers.add("x-ti-app-id", "123456");
headers.add("x-ti-secret-code", "123456");

// 发送OCR识别请求
String response;
try {
    response = RestTemplateUtil.postStream(restTemplate, textRecUrl, file.getBytes(), headers);
} catch (IOException e) {
    // 文件读取失败，记录错误日志并返回空结果
    log.error("识别身份证失败{}", e.getMessage(), e);
    ApiResponse.saveGlobalMessage(e.getMessage());
    return ocrResponseVOs;
}
```

解析结果

```java
// 解析API响应
if (StringUtils.hasText(response)) {
    JSONObject jsonResponse = JsonUtils.parse(response, JSONObject.class);
    Integer code = jsonResponse.getInteger("code");

    // 判断API调用是否成功（状态码200表示成功）
    if (200 == code) {
        // 获取识别结果中的文本行列表
        JSONArray itemList = jsonResponse.getJSONObject("result").getJSONArray("lines");

        // 遍历每行识别结果，封装为OcrResponseVO对象
        for (int idx = 0; idx < itemList.size(); idx++) {
            JSONObject item = itemList.getJSONObject(idx);
            OcrResponseVO ocrResponseVO = new OcrResponseVO();
            // 设置识别的文本内容
            ocrResponseVO.setText(item.getObject("text", String.class));
            // 设置识别置信度分数（0-1之间，越高越准确）
            ocrResponseVO.setScore(item.getFloat("score"));
            // 设置文本类型
            ocrResponseVO.setType(item.getObject("type", String.class));
            // 设置文本在图片中的位置坐标
            ocrResponseVO.setPosition(item.getObject("position", String.class));
            // 设置是否为手写体（1表示手写，0表示印刷体）
            ocrResponseVO.setHandwritten(item.getInteger("handwritten"));
            ocrResponseVOs.add(ocrResponseVO);
        }
    } else {
        // API调用失败，保存错误信息
        ApiResponse.saveGlobalMessage(jsonResponse.getString("message"));
    }
}
return ocrResponseVOs;
```

## ICR

ICR 可以支持手写体，当然印刷体也可以识别，因此其识别场景更广，但准确率也更低。

身份证场景下，需要的请求参数如下

```java
@PostMapping("/recognize_id_card")
@Operation(summary = "icr身份证识别接口")
@ResponseBody
public ApiResponse<IcrResponseVO> recognizeIdCard(@Parameter(name = "身份证件照", required = true) @RequestParam MultipartFile file,
													@Parameter(name = "场景编码", required = true) @RequestParam String scene,
													@Parameter(name = "唯一id", required = true) @RequestParam String sessionId,
													@Parameter(name = "文件类型", required = true) @RequestParam String fileType,
													@Parameter(name = "操作人员id", required = true) @RequestParam String scanUser,
													@Parameter(name = "流水号") @RequestParam(required = false) String serialNo,
													@Parameter(name = "应用场景名称") @RequestParam(required = false) String serverName) {
	IcrResponseVO icrRecognizeVO = icrRecognizeService.recognizeIdCard(file, scene, sessionId, fileType, scanUser, serialNo, serverName);
	if (ObjectUtils.isEmpty(icrRecognizeVO)) {
		ApiResponse<IcrResponseVO> error = ApiResponse.data(ResultCode.FAILURE.getCode(), icrRecognizeVO, "身份证识别接口");
		ApiResponse.setGlobalMessage(error);
		return error;
	}
	return ApiResponse.data(200, icrRecognizeVO, "身份证识别接口");
}
```

银行卡、社保卡、营业执照的操作同理。具体需要参照 [TextIn文档](https://www.textin.com/document/display_type_7) 中的内容来构造参数并发送 resttemplate 请求。