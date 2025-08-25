---
title: leetcode热题100官方题解 - 1
date: 2025-08-07 21:51:09
tags: [算法]
---

{% note warning %}
以下几篇均为leetcode热门100题中的原题与官方题解。部分会做的题目做好了会以蓝色注释放出来。
{% endnote %}

### 哈希

#### 两数之和

给定一个整数数组 `nums` 和一个整数目标值 `target`，请你在该数组中找出 和为目标值 `target`  的那两个 整数，并返回它们的数组下标。
你可以假设每种输入只会对应一个答案，并且你不能使用两次相同的元素。
你可以按任意顺序返回答案。

示例：
    输入：`nums = [2,7,11,15], target = 9`
    输出：`[0,1]`
    解释：因为 `nums[0] + nums[1] == 9` ，返回 `[0, 1]` 。

该题使用复杂度为$O(N^2)$暴力解法也不是不行。更好的解法是使用哈希表减少寻找`target - x`的时间复杂度。

```java
public int[] twoSum(int[] nums, int target) {
    Map<Integer, Integer> hash = new HashMap<>();
    for(int i = 0; i < nums.length; ++i) {
        if (hash.containsKey(target - nums[i]))
            return new int[]{hash.get(target - nums[i]), i};
        hash.put(nums[i], i);
    }
    return new int[0];
}
```

每一个遍历过的值都放在 `hashMap` 中，在遍历中的值在寻找`target - x`时需要的时间复杂度不再是$O(n)$而是近似为$O(1)$。

#### 字母异位词分组

给你一个字符串数组，请你将**字母异位词** (通过重新排列不同单词或短语的字母而形成的单词或短语，并使用所有原字母一次) 组合在一起。可以按任意顺序返回结果列表。

示例：
    输入: `strs = ["eat", "tea", "tan", "ate", "nat", "bat"]`
    输出: `[["bat"],["nat","tan"],["ate","eat","tea"]]`
    解释：
    在 `strs` 中没有字符串可以通过重新排列来形成 `"bat"`。
    字符串 `"nat"` 和 `"tan"` 是字母异位词，因为它们可以重新排列以形成彼此。
    字符串 `"ate"` ，`"eat"` 和 "`tea"` 是字母异位词，因为它们可以重新排列以形成彼此。

该题也需要哈希，将所有的异位词分到同一个列表中，通过统计每个字符串中每个字母的出现次数，生成唯一的“特征键”来区分不同的异位词组。首先遍历题目字符串数组，对指定字符串中的字母出现次数进行统计，最后形成形如 `"a1e1t1"`这样的字符串，作为哈希表的键。利用这个键，使用`getOrDefault`方法检查是否存在对应键的列表（没有则创建一个）。最后返回指定`List`。

```java
class Solution {
    public List<List<String>> groupAnagrams(String[] strs) {
        Map<String, List<String>> map = new HashMap<String, List<String>>();
        for (String str : strs) {
            int[] counts = new int[26];
            int length = str.length();
            for (int i = 0; i < length; i++)
                counts[str.charAt(i) - 'a']++;
            StringBuffer sb = new StringBuffer();
            for (int i = 0; i < 26; i++) {
                if (counts[i] != 0) {
                    sb.append((char) ('a' + i));
                    sb.append(counts[i]);
                }
            }
            String key = sb.toString();
            List<String> list = map.getOrDefault(key, new ArrayList<String>());
            list.add(str);
            map.put(key, list);
        }
        return new ArrayList<List<String>>(map.values());
    }
}
```

当然，作为键的字符串也可以是字母通过排序后的字符串，此处不另附代码。

{% note info %}
字符串处理太麻烦了，有没有更简便一点的键呢？有的，定义好26个质数，不同字母下质数相乘的结果不可能一样，可以由此定义不同的键

```java
class Solution {
    public List<List<String>> groupAnagrams(String[] strs) {
        int[] prime = {2,  3,  5,  7,  11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101};
        Map<Double, List<String>> list = new HashMap<>();
        for(String str : strs) {
            char[] split = str.toCharArray();
            double multipy = 1.0;
            for(char c : split) {
                multiply *= prime[c - 'a'];
            }

            List<String> tempList = list.getOrDefault(multiply, new ArrayList<>());
            tempList.add(str);
            list.put(multiply, tempList);
        }
        return new ArrayList<List<String>>(list.values());
    }
}
```

注意此处`multiply`的类型，在leetcode给的数据下，无论是`Integer`还是`Long`都存不下，必须是`Double`。
{% endnote %}

#### 最长连续序列

给定一个未排序的整数数组 `nums` ，找出数字连续的最长序列（不要求序列元素在原数组中连续）的长度。请你设计并实现时间复杂度为$O(n)$的算法解决此问题。

示例：
    输入：`nums = [100,4,200,1,3,2]`
    输出：`4`
    解释：最长数字连续序列是 [1, 2, 3, 4]。它的长度为 `4`。

在题解中，我们可以使用`HashSet`进行去重，然后查找元素的开头。如果不是元素的开头则直接跳过，是则循环寻找其序列，最后计算长度。

```java
class Solution {
    public int longestConsecutive(int[] nums) {
        int temp, max = 0, num;
        Set<Integer> set = new HashSet<>();
        for(int i : nums){
            set.add(i);
        }
        for(int i : set) {
            temp = 1;
            if(!set.contains(i - 1)){
                num = i;
                while (set.contains(num + 1)) {
                    num++;
                    temp++;
                }
                max = Math.max(max, temp);
            }
        }
        return max;
    }
}
```

在示例中，能够开头的序列为`[100,200]`和`[1,2,3,4]`，代码能找到这两列，然后得到数字2和4，最后输出4。

{% note info %}
也可以直接排序后找结果，虽然复杂度由$O(n)$增加至$O(n\log_2n)$，但好懂多了。而且这套代码为什么比官方的还快？

```java
class Solution {
    public int longestConsecutive(int[] nums) {
        if(nums.length == 0)
            return 0;
        int temp = 0, max = 0;
        Arrays.sort(nums);
        for(int i = 0; i < nums.length - 1; i++) {
            if(nums[i + 1] - nums[i] == 1) {
                temp++;
            } else if (nums[i + 1] - nums[i] == 0) {
                continue;
            } else {
                temp++;
                max = Math.max(temp, max);
                temp = 0;
            }
        }
        temp++;
        max = Math.max(temp, max);
        return max;
    }
}
```

{% endnote %}

### 双指针

#### 移动零

给定一个数组 `nums`，编写一个函数将所有 `0` 移动到数组的末尾，同时保持非零元素的相对顺序。
请注意 ，必须在不复制数组的情况下原地对数组进行操作。

示例:
    输入: `nums = [0,1,0,3,12]`
    输出: `[1,3,12,0,0]`

使用快慢指针，快指针向前，慢指针在最近的一个0处，快指针将非0数与慢指针交换。

```java
class Solution {
    public void moveZeroes(int[] nums) {
        int n, left = 0, right = 0;
        while (right < nums.length) {
            if (nums[right] != 0) {
                n = nums[left];
                nums[left] = nums[right];
                nums[right] = n;
                left++;
            }
            right++;
        }
    }
}
```

一开始快慢指针都是同一个，自己和自己交换。当出现0时快慢指针错开一位或多位，快指针指向非0数，与慢指针的0进行交换。

{% note info %}
提交做法

```java
class Solution {
    public void moveZeroes(int[] nums) {
        int fast = 0, slow = 0, length = nums.length;
        while (fast != length) {
            if (fast == slow) {
                if (nums[fast] == 0) {
                    fast++;
                } else {
                    fast++;
                    slow++;
                }
            } else {
                if (nums[fast] != 0) {
                    nums[slow] = nums[fast];
                    nums[fast] = 0;
                    slow++;
                    fast++;
                } else {
                    fast++;
                }
            }
        }
        while (slow != fast) {
            nums[slow] = 0;
            slow++;
        }
    }
}
```

{% endnote %}

#### 乘最多水的容器

给定一个长度为 `n` 的整数数组 `height` 。有 `n` 条垂线，第 `i` 条线的两个端点是 `(i, 0)` 和 `(i, height[i])` 。
找出其中的两条线，使得它们与 `x` 轴共同构成的容器可以容纳最多的水。
返回容器可以储存的最大水量。

示例：
    输入：`[1,8,6,2,5,4,8,3,7]`
    输出：`49`
    解释：图中垂直线代表输入数组 `[1,8,6,2,5,4,8,3,7]`。在此情况下，容器能够容纳水（表示为蓝色部分）的最大值为 `49`。
![图例](question_11.jpg)

本题可以使用左右两个指针。两个指针所指向的数值代表容器高，计算出面积后，左右指针中哪个指向数值比较小，就让哪个指针向中间靠拢。因为向中间靠拢更有可能遇到更大的数字。

```java
class Solution {
    public int maxArea(int[] height) {
        int left = 0, right = height.length - 1, area, maxArea = 0;
        while(left != right) {
            area = Math.min(height[left], height[right]) * (right - left);
            maxArea = Math.max(maxArea, area);
            if (height[left] > height[right]) right -= 1;
            else left += 1;
        }
        return maxArea;
    }
}
```

#### 三数之和

给你一个整数数组 `nums` ，判断是否存在三元组 `[nums[i], nums[j], nums[k]]` 满足 `i != j`、`i != k` 且 `j != k` ，同时还满足 `nums[i] + nums[j] + nums[k] == 0` 。请你返回所有和为 `0` 且不重复的三元组。
注意：答案中不可以包含重复的三元组。

示例：
    输入：`nums = [-1,0,1,2,-1,-4]`
    输出：`[[-1,-1,2],[-1,0,1]]`
    解释：
    `nums[0] + nums[1] + nums[2] = (-1) + 0 + 1 = 0` 。
    `nums[1] + nums[2] + nums[4] = 0 + 1 + (-1) = 0`。
    `nums[0] + nums[3] + nums[4] = (-1) + 2 + (-1) = 0`。
    不同的三元组是 `[-1,0,1]` 和 `[-1,-1,2]` 。
    注意，输出的顺序和三元组的顺序并不重要。

最坏的情况下，我们考虑全部遍历的情况。首先，由于题目要求不重复，需要保证三重循环下的枚举元素都不一样，因此有必要对数组元素进行排序。

```cpp
nums.sort();
for(int i = 0; i < nums.size(); ++i)
    if(!i || nums[i] != nums[i - 1])
        for(int j = i + 1; j < nums.size(); ++j)
            if(j = i + 1 || nums[j] != nums[j - 1])
                for(int k = j + 1; k < nums.size(); ++k)
                    if(k = j + 1 || nums[k] != nums[k - 1])
                        if(nums[i] + nums[j] + nums[k] == 0)
                        {
                            ...
                        }
```

复杂度为$O(n^3)$。
我们注意到，当我们固定了`i`，并且找到了`j` `k`以满足`i + j + k = 0`后，再次寻找则只会是`j' > j`，因此必有`k' < k`，于是我们可以保持第二重循环不变，将第三重循环变成一个从右向左移动的指针。

```cpp
nums.sort()
for(int i = 0; i < nums.size(); ++i)
    if(!i || nums[i] != nums[i - 1])
    {
        int k = nums.size() - 1;
        for(int j = i + i; j < nums.size(); ++j)
            if(j = i + 1 || nums[j] != nums[j - 1])
            {
                while(nums[i] + nums[j] + nums[k--] > 0 && j != k);
                if(nums[i] + nums[j] + nums[k] == 0)
                {
                    ...
                }
            }
    }
```

于是复杂度可以降到$O(n^2)$。
完整的Java代码如下

```java
class Solution {
    public List<List<Integer>> threeSum(int[] nums) {
        Arrays.sort(nums);
        int length = nums.length, k;
        Set<List<Integer>> set = new HashSet<>();
        for(int i = 0; i < length; ++i) {
            if(i == 0 || nums[i] != nums[i - 1]) {
                k = length - 1;
                for(int j = i + 1; j < length; ++j)
                    if(j == i + 1 || nums[j] != nums[j - 1]) {
                        while(j < k && nums[i] + nums[j] + nums[k] > 0) --k;
                        if(j == k) break;
                        if(nums[i] + nums[j] + nums[k] == 0) {
                            set.add(new ArrayList<>(Arrays.asList(nums[i], nums[j], nums[k])));
                        }
                    }
            }
        }
        return new ArrayList<>(set);
    }
}
```

#### **接雨水**

给定 `n` 个非负整数表示每个宽度为 `1` 的柱子的高度图，计算按此排列的柱子，下雨之后能接多少雨水。

示例：
    输入：`height = [0,1,0,2,1,0,1,3,2,1,2,1]`
    输出：`6`
    解释：上面是由数组 `[0,1,0,2,1,0,1,3,2,1,2,1]` 表示的高度图，在这种情况下，可以接 6 个单位的雨水（蓝色部分表示雨水）。
![图片示例](rainwatertrap.png)

最朴素的做法，就是对于数组中的每个元素，分别记录其左边和右边的最大高度，然后计算每个下标位置能接的水量。这样的复杂度为$O(n^2)$。

##### 解法一：前缀和/动态规划

参考：[https://www.bilibili.com/video/BV1TSPeeGEHC](https://www.bilibili.com/video/BV1TSPeeGEHC)

不去单独计算每个元素左右两边的最大高度，而是另外开数组，记录截至该元素前的左边右边最大高度，这样只需要遍历固定次数即可。时间复杂度可以降至$O(n)$。

或者用动态规划的思路去解决。传统做法主要的时间开销都在于对每个下标位置向两边扫描。如果提前处理好则可以将时间降到$O(n)$

![解法](rainwatertrapsolution.png)

```java
class Solution {
    public int trap(int[] height) {
        int length = height.length, result = 0;
        int[] left = new int[length], right = new int[length];
        left[0] = height[0];
        right[length - 1] = height[length - 1];
        for(int i = 1; i < length; i++) {
            left[i] = Math.max(left[i - 1], height[i]);
            right[length - 1 - i] = Math.max(right[length - i], height[length - 1 - i]);
        }
        for(int i = 0; i < length; i++) {
            result += Math.min(left[i], right[i]) - height[i];
        }
        return result;
    }
}
```

##### 解法二：单调栈

维护一个单调栈，使得从栈底到栈顶对应的元素递减

```java
class Solution {
    public int trap(int[] height) {
        int ans = 0;
        Deque<Integer> stack = new LinkedList<Integer>();
        int n = height.length;
        for (int i = 0; i < n; ++i) {
            while (!stack.isEmpty() && height[i] > height[stack.peek()]) {
                int top = stack.pop();
                if (stack.isEmpty()) {
                    break;
                }
                int left = stack.peek();
                int currWidth = i - left - 1;
                int currHeight = Math.min(height[left], height[i]) - height[top];
                ans += currWidth * currHeight;
            }
            stack.push(i);
        }
        return ans;
    }
}
```

当下一个元素比上一个元素小时，压入栈；当下一个元素比上一个元素大时，弹出元素并增加差值，直到使栈符合规则为止。

##### 解法三：双指针

维护两个指针`left`和`right`，及对应的最大值。让这两个指针不断靠拢，同时更新最大值。

```java
class Solution {
    public int trap(int[] height) {
        int ans = 0;
        int left = 0, right = height.length - 1;
        int leftMax = 0, rightMax = 0;
        while (left < right) {
            leftMax = Math.max(leftMax, height[left]);
            rightMax = Math.max(rightMax, height[right]);
            if (height[left] < height[right]) {
                ans += leftMax - height[left];
                ++left;
            } else {
                ans += rightMax - height[right];
                --right;
            }
        }
        return ans;
    }
}
```

### 栈

#### 有效的括号

给定一个只包括 `'('`，`')'`，`'{'`，`'}'`，`'['`，`']'` 的字符串 s ，判断字符串是否有效。
有效字符串需满足：

- 左括号必须用相同类型的右括号闭合。
- 左括号必须以正确的顺序闭合。
- 每个右括号都有一个对应的相同类型的左括号。

示例：
    输入：`s = "()[]{}"`
    输出：`true`

同样是一个栈，自己写的就容易漏状况，唉

```java
class Solution {
    public boolean isValid(String s) {
        int n = s.length();
        if (n % 2 == 1) {
            return false;
        }

        Map<Character, Character> pairs = new HashMap<Character, Character>() {{
            put(')', '(');
            put(']', '[');
            put('}', '{');
        }};
        Deque<Character> stack = new LinkedList<Character>();
        for (int i = 0; i < n; i++) {
            char ch = s.charAt(i);
            if (pairs.containsKey(ch)) {
                if (stack.isEmpty() || stack.peek() != pairs.get(ch))
                    return false;
                stack.pop();
            } else
                stack.push(ch);
        }
        return stack.isEmpty();
    }
}
```

一个栈，遍历字符串。当遇到右括号时，检查栈顶是否有对应的左括号，有就弹出。否则一律弹入

#### 最小栈

设计一个支持 `push` ，`pop` ，`top` 操作，并能在常数时间内检索到最小元素的栈。
实现 `MinStack` 类:

- `MinStack()` 初始化堆栈对象。
- `void push(int val)` 将元素val推入堆栈。
- `void pop()` 删除堆栈顶部的元素。
- `int top()` 获取堆栈顶部的元素。
- `int getMin()` 获取堆栈中的最小元素。

示例:

输入：
    `["MinStack","push","push","push","getMin","pop","top","getMin"]`
    `[[],[-2],[0],[-3],[],[],[],[]]`

输出：
    `[null,null,null,null,-3,null,0,-2]`

解释：
    MinStack minStack = new MinStack();
    minStack.push(-2);
    minStack.push(0);
    minStack.push(-3);
    minStack.getMin();   --> 返回 -3.
    minStack.pop();
    minStack.top();      --> 返回 0.
    minStack.getMin();   --> 返回 -2.

{% note info %}
使用双向链表实现栈的功能，由于题目保证不对空栈实行弹出操作，从而考验报错，这样就不需要边界检查了。最后可以实现最快速度和不错的内存消耗。而每个节点都可以存储一个当前节点前的最小值以实现快速存取功能。

```java
class MinStack {
    class Node {
        int val;
        int min;
        Node next;
        Node last;
        Node(int val) {
            this.val = val;
        }
    }
    Node node;

    public MinStack() {
        node = new Node(0);
        node.min = Integer.MAX_VALUE;
    }
    
    public void push(int val) {
        node.next = new Node(val);
        node.next.last = node;
        node = node.next;
        node.min = node.last.min < val ? node.last.min : val;
    }
    
    public void pop() {
        node = node.last;
        node.next = null;
    }
    
    public int top() {
        return node.val;
    }
    
    public int getMin() {
        return node.min;
    }
}
```

{% endnote %}

而题解是使用辅助栈存放最小值，当当前元素的值比栈顶小时则放入。

#### 字符串解码

给定一个经过编码的字符串，返回它解码后的字符串。

编码规则为: `k[encoded_string]`，表示其中方括号内部的 `encoded_string` 正好重复 `k` 次。注意 `k` 保证为正整数。
你可以认为输入字符串总是有效的；输入字符串中没有额外的空格，且输入的方括号总是符合格式要求的。
此外，你可以认为原始数据不包含数字，所有的数字只表示重复的次数 `k` ，例如不会出现像 `3a` 或 `2[4]` 的输入。

示例：
    输入：s = "3[a2[c]]"
    输出："accaccacc"

{% note info %}
我的丢人遍历法，时间击败11%，空间击败5%

```java
class Solution {
    public String decodeString(String s) {
        return recursive(s);
    }

    public String recursive(String s) {
        String ans = new String();
        int repeat = 0;
        for(int i = 0; i < s.length(); i++) {
            if(s.charAt(i) >= 'a' && s.charAt(i) <= 'z')
                ans = ans + s.charAt(i);
            else if(s.charAt(i) >= '0' && s.charAt(i) <= '9')
                repeat = repeat * 10 + s.charAt(i) - '0';
            else if(s.charAt(i) == '[') {
                for(int j = i + 1, counter = 0; j < s.length(); j++)
                    if(s.charAt(j) == ']') {
                        if(counter == 0) {
                            for(; repeat > 0; repeat--)
                                ans = ans + recursive(s.substring(i + 1, j));
                            i = j;
                            break;
                        }
                    else
                        counter--;
                    }
                    else if(s.charAt(j) == '[')
                        counter++;
            }
        }
        return ans;
    }
}
```

{% endnote %}

##### 栈

对于括号的嵌套，比如`2[a2[bc]]`，可以先转化成`2[abcbc]`，再转化成`abcabcabc`。以下两种方法都是基于这种方式实现的。
我们维护一个栈，并遍历这个栈

- 当前字符为数位，解析出一个数字并进栈
- 当前字符为字母或左括号，直接进栈
- 右括号，开始出栈，一直到左括号出栈。出站的序列反转后拼接成一个字符串。此时取出栈顶的数字，根据这个次数和字符串构造出新的字符串闭关进栈

也可以使用不定长数组来模拟栈操作。

```java
class Solution {
    int ptr;
    public String decodeString(String s) {
        LinkedList<String> stk = new LinkedList<String>();
        ptr = 0;

        while (ptr < s.length()) {
            char cur = s.charAt(ptr);
            if (Character.isDigit(cur)) { // 获取一个数字并进栈
                String digits = getDigits(s);
                stk.addLast(digits);
            } else if (Character.isLetter(cur) || cur == '[') // 获取一个字母或左括号并进栈
                stk.addLast(String.valueOf(s.charAt(ptr++)));
            
            else { // 右括号
                ++ptr;
                LinkedList<String> sub = new LinkedList<String>();
                while (!"[".equals(stk.peekLast()))
                    sub.addLast(stk.removeLast());
                Collections.reverse(sub);
                // 左括号出栈
                stk.removeLast();
                int repTime = Integer.parseInt(stk.removeLast());
                StringBuffer t = new StringBuffer();
                String o = getString(sub);
                // 构造字符串
                while (repTime-- > 0)
                    t.append(o);
                stk.addLast(t.toString());
            }
        }

        return getString(stk);
    }

    public String getDigits(String s) {
        StringBuffer ret = new StringBuffer();
        while (Character.isDigit(s.charAt(ptr)))
            ret.append(s.charAt(ptr++));
        return ret.toString();
    }

    public String getString(LinkedList<String> v) {
        StringBuffer ret = new StringBuffer();
        for (String s : v)
            ret.append(s);
        return ret.toString();
    }
}
```

##### 递归

```java
class Solution {
    String src;
    int ptr;

    public String decodeString(String s) {
        src = s;
        ptr = 0;
        return getString();
    }

    public String getString() {
        if (ptr == src.length() || src.charAt(ptr) == ']')
            return "";

        char cur = src.charAt(ptr);
        int repTime = 1;
        String ret = "";

        if (Character.isDigit(cur)) {
            repTime = getDigits(); 
            // 过滤左括号
            ++ptr;
            String str = getString();
            // 过滤右括号
            ++ptr;
            // 构造字符串
            while (repTime-- > 0)
                ret += str;
        } else if (Character.isLetter(cur))
            ret = String.valueOf(src.charAt(ptr++));
        
        return ret + getString();
    }

    public int getDigits() {
        int ret = 0;
        while (ptr < src.length() && Character.isDigit(src.charAt(ptr)))
            ret = ret * 10 + src.charAt(ptr++) - '0';
        return ret;
    }
}
```

#### 每日温度

给定一个整数数组 temperatures ，表示每天的温度，返回一个数组 `answer` ，其中 `answer[i]` 是指对于第 i 天，下一个更高温度出现在几天后。如果气温在这之后都不会升高，请在该位置用 `0` 来代替。

示例:
    输入: `temperatures = [73,74,75,71,69,72,76,73]`
    输出: `[1,1,4,2,1,1,0,0]`

{% note info %}
本人的单调栈做法

```java
class Solution {
    public int[] dailyTemperatures(int[] temperatures) {
        Deque<Integer> stack = new LinkedList<>();
        int[] ans = new int[temperatures.length];
        for(int i = 0; i < temperatures.length; i++) {
            while(!(stack.isEmpty() || temperatures[i] <= temperatures[stack.peek()])) {
                ans[stack.peek()] = i - stack.peek();
                stack.pop();
            }
            stack.push(i);
        }
        while(!stack.isEmpty())
            ans[stack.pop()] = 0;
        return ans;
    }
}
```

{% endnote %}

维护一个存储下标的单调栈，从栈底到栈顶的温度列表中的温度依次递减。
以下是官解的代码

```java
class Solution {
    public int[] dailyTemperatures(int[] temperatures) {
        int length = temperatures.length;
        int[] ans = new int[length];
        Deque<Integer> stack = new LinkedList<Integer>();
        for (int i = 0; i < length; i++) {
            int temperature = temperatures[i];
            while (!stack.isEmpty() && temperature > temperatures[stack.peek()]) {
                int prevIndex = stack.pop();
                ans[prevIndex] = i - prevIndex;
            }
            stack.push(i);
        }
        return ans;
    }
}
```

{% note success %}
看来剩下的元素其实不用处理，毕竟默认值就是0了。于是用时就提高了2ms。
{% endnote %}

#### 柱状图中的最大矩形

给定 `n` 个非负整数，用来表示柱状图中各个柱子的高度。每个柱子彼此相邻，且宽度为 `1` 。
求在该柱状图中，能够勾勒出来的矩形的最大面积。

示例：
![示例](histogram.jpg)
    输入：`heights = [2,1,5,6,2,3]`
    输出：`10`
    解释：最大的矩形为图中红色区域，面积为 `10`

维护`left`数组，存储每个柱子左边第一个比它小的柱子的索引，没有则设置为`-1`
维护`right`数组，存储每个柱子右边第一个比它小的柱子的索引，没有则设置为`n`
维护一个单调栈，比栈顶大的元素的索引放入，以方便找到左右边界。左边界在压栈时确定，右边界的弹出时确定，栈空时弹入`-1`作左边界
最后利用`left`和`right`中的数据计算面积

```java
class Solution {
    public int largestRectangleArea(int[] heights) {
        int n = heights.length;
        int[] left = new int[n];
        int[] right = new int[n];
        Arrays.fill(right, n);
        
        Deque<Integer> mono_stack = new ArrayDeque<Integer>();
        for (int i = 0; i < n; ++i) {
            while (!mono_stack.isEmpty() && heights[mono_stack.peek()] >= heights[i]) {
                right[mono_stack.peek()] = i;
                mono_stack.pop();
            }
            left[i] = (mono_stack.isEmpty() ? -1 : mono_stack.peek());
            mono_stack.push(i);
        }
        
        int ans = 0;
        for (int i = 0; i < n; ++i) {
            ans = Math.max(ans, (right[i] - left[i] - 1) * heights[i]);
        }
        return ans;
    }
}
```
