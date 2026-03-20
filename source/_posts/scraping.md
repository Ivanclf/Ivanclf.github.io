---
title: 爬虫与数据分析
date: 2025-08-01 12:49:53
tags: [日常, 碎片知识]
---

此处的爬虫和数据分析的脚本均由 ai 生成。不同的网站的反爬措施也不同，爬虫的写法也不太一样。

## B站评论

首先需要准备好请求信息

```python
oid = "{视频的oid}"
cookie = "{你的访问Cookie}"
Referer = "https://www.bilibili.com/video/{BV号}"
headers = {
    'User-Agent': '{你的UA}',
    'Referer': Referer,
    'Cookie': cookie
}
```

cookie 和 UA 需要在 F12 中随便找个请求截取。而 oid 需要找到视频页的源码

![右击网页菜单，点击查看源码或 View Page Source](right-click.png)

然后搜索 oid，一直找到视频的 oid 号。

然后爬取评论

```python
def fetch_comments(oid, page=1):
    url = f'https://api.bilibili.com/x/v2/reply/main'
    params = {
        'type': 1,
        'oid': oid,
        'mode': 3,
        'next': page
    }
    try:
        resp = requests.get(url, headers=headers, params=params, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        if data.get('code', 0) != 0:
            print(f"接口错误，code={data.get('code')}, message={data.get('message')}")
        return data
    except Exception as e:
        print(f"请求异常: {e}")
        return {}
```

一次爬取 10 条。然后通过数组存储，并不断追加

```python
def parse_comments(data):
    comments = []
    replies = data.get('data', {}).get('replies', [])
    for reply in replies:
        uid = reply.get('member', {}).get('mid', '')
        content = reply.get('content', {}).get('message', '')
        comments.append([uid, content])
    return comments
```

最后将数据归总到 csv 文件中，并实现翻页效果。

```python
def main():
    page = 1
    with open('./data.csv', 'w', newline='', encoding='utf-8-sig') as f:
        writer = csv.writer(f)
        writer.writerow(['用户ID', '评论内容'])
        while True:
            data = fetch_comments(oid, page)
            if data.get('code', 0) != 0:
                break
            comments = parse_comments(data)
            if not comments:
                break
            writer.writerows(comments)
            print(f'Fetched page {page}, {len(comments)} comments')
            page += 1
            time.sleep(random.uniform(1.0, 3.0))
            if not data.get('data', {}).get('cursor', {}).get('is_end', True):
                continue
            else:
                break
    print('导出完成，保存到data.csv')
```

于是就可以获得所有的评论并导出成 csv 文件中了。最后可以依次进行词云分析和重复评论分析。分析需要用到 pandas 库用于读取和展示数据，jieba 库用于分词。

```python
def read_comments():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    file_path = os.path.join(current_dir, '{data.csv路径}')
    
    try:
        df = pd.read_csv(file_path, encoding='utf-8')
        print(f'成功读取文件：{file_path}')
        return df['评论内容'].tolist()
    except Exception as e:
        print(f"读取文件失败：{e}")
        return []
```

分析词云

```python
def analyze_comments(comments):
    try:
        print("开始分词处理...")
        words = []
        for comment in comments:
            if isinstance(comment, str):
                words.extend(jieba.lcut(comment))
        
        word_freq = Counter(words)
        
        # 过滤掉一些停用词
        stop_words = {
            '的', '了', '啊', '吧', '吗', '呢', '啦', '呀', '嘛', '哦', '哈', '呐', '嗯', '诶', 
            '我', '你', '他', '她', '它', '我们', '你们', '他们', '这', '那', '这个', '那个', '这些', '那些', '什么', '谁', '哪', '哪个', '哪些',
            '都', '也', '很', '真', '太', '好', '还', '别', '就', '才', '可', '要', '怎么', '怎样', '这样', '那样','真的', '这么', '那么', '已经', '只能'
            '在', '从', '和', '与', '跟', '同', '及', '或', '而', '但是', '可是', '然后', '因为', '所以', '如果', '要是','还是', '就是', 
            '是', '有', '没', '没有', '不', '不是', '不要', '能', '可以', '应该', '需要', '想', '觉得', '不会', '不能', 
            '一个', '一些', '几个', '好多', '很多', '非常', 
            # 表情包等
            'doge', 'up', 'b23', 'UP', 'ok', 'OK', 'http', 'https', 'call', 'tv', '\"', '“', '”', 
        }
        # 过滤掉形如[xxx]的内容
        word_freq = Counter(word for word in words 
                    if not re.fullmatch(r'^\[.*?]$', word))
        
        word_freq = {word: freq for word, freq in word_freq.items() 
                     if word not in stop_words and len(word) > 1 and freq >= 5}
        
        # 转换为DataFrame并排序
        word_df = pd.DataFrame(word_freq.items(), columns=['词语', '出现次数'])
        word_df = word_df.sort_values('出现次数', ascending=False)
        
        return word_df
    except Exception as e:
        print(f"分析词频时出错：{e}")
        print(traceback.format_exc())  # 打印详细错误堆栈
        return pd.DataFrame(columns=['词语', '出现次数'])
```

进行相同评论分析

```python
def analyze_duplicate_comments(comments):
    try:
        print("开始分析重复评论...")
        comment_freq = Counter(comments)
        comment_freq = {comment: freq for comment, freq in comment_freq.items() if freq > 1}
        comment_df = pd.DataFrame(comment_freq.items(), columns=['评论内容', '重复次数'])
        comment_df = comment_df.sort_values('重复次数', ascending=False)
        return comment_df
    except Exception as e:
        print(f"分析重复评论时出错：{e}")
        print(traceback.format_exc())
        return pd.DataFrame(columns=['评论内容', '重复次数'])
```

入口

```python
def main():
    try:
        print("\n=== 1. 读取评论 ===")
        comments = read_comments()
        if not comments:
            print("没有读取到评论数据，程序终止")
            return
        print(f"共读取到 {len(comments)} 条评论")
        print("\n=== 2. 分析词频 ===")
        word_df = analyze_comments(comments)
        print("\n=== 3. 分析重复评论 ===")
        duplicate_df = analyze_duplicate_comments(comments)
        current_dir = os.path.dirname(os.path.abspath(__file__))
        print("\n=== 4. 保存分析结果 ===")
        
        if not word_df.empty or not duplicate_df.empty:
            try:
                if not word_df.empty:
                    word_freq_path = os.path.join(current_dir, 'word_freq.csv')
                    word_df.to_csv(word_freq_path, index=False, encoding='utf-8-sig')

                if not duplicate_df.empty:
                    duplicate_path = os.path.join(current_dir, 'duplicate_comments.csv')
                    duplicate_df.to_csv(duplicate_path, index=False, encoding='utf-8-sig')
                
                print('分析完成！结果已保存')
                print('\n词频统计 Top 10:')
                print(word_df.head(10))
                print('\n重复评论 Top 10:')
                print(duplicate_df.head(10))
                
                try:
                    os.startfile(word_freq_path)
                except:
                    pass
            except Exception as e:
                print(f"保存结果时出错: {e}")
        else:
            print("没有分析结果可以保存")
            
        print("\n=== 处理完成 ===")
    except Exception as e:
        print(f"处理过程中出错: {e}")
```