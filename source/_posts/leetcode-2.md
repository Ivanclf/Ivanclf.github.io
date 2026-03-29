---
title: leetcode热题100官方题解 - 2
date: 2025-08-08 17:14:32
tags: [算法, 滑动窗口, 双指针, 链表]
category: leetcode
---

### 滑动窗口

#### **无重复字符的最长子串**

给定一个字符串 s ，请你找出其中不含有重复字符的最长子串的长度。

示例:
    输入: s = "abcabcbb"
    输出: 3
    解释: 因为无重复字符的最长子串是 "abc"，所以其长度为 3。
既然字母不能重复，那么最直接的办法就是一个个字符去遍历，当遇到重复字符时就重新开始遍历。使用双指针可以完成这个功能

```java
class Solution {
    public int lengthOfLongestSubstring(String s) {
        Set<Character> occ = new HashSet<Character>();
        int n = s.length(), right = -1, ans = 0;
        for (int left = 0; left < n; ++i) {
            if (left != 0) {
                occ.remove(s.charAt(i - 1));
            }
            while (right + 1 < n && !occ.contains(s.charAt(right + 1))) {
                occ.add(s.charAt(right + 1));
                ++right;
            }
            ans = Math.max(ans, right - i + 1);
        }
        return ans;
    }
}
```

当左指针 `i` 不在起始位置时，集合需要删掉 `i`前面的字母，然后右指针往后遍历，直到遇到相同字母为止。

{% note info %}
或者这样

```java
class Solution {
    public int lengthOfLongestSubstring(String s) {
        int[] index = new int[128]; // 记录每个字符最后一次出现的位置 +1
        int maxLen = 0;
        int left = 0;

        for (int right = 0; right < s.length(); right++) {
            char ch = s.charAt(right);
            left = Math.max(left, index[ch]);
            maxLen = Math.max(maxLen, right - left + 1);
            index[ch] = right + 1; 
        }

        return maxLen;
    }
}
```

第一个max函数用于比较右指针字符上一次出现的位置是否在左指针后，是则让左指针移动到后面一位。

{% endnote %}

#### 找到字符串中的所有字母异位词

给定两个字符串 s 和 p，找到 s 中所有 p 的 异位词 的子串，返回这些子串的起始索引。不考虑答案输出的顺序。

示例:
    输入: `s = "cbaebabacd", p = "abc"`
    输出: `[0,6]`
    解释:
    起始索引等于 `0` 的子串是 `"cba"`, 它是 `"abc"` 的异位词。
    起始索引等于 `6` 的子串是 `"bac"`, 它是 `"abc"` 的异位词。
由于异位词的长度一定是一样的的，所以可以指定滑动窗口的长度

```java
class Solution {
    public List<Integer> findAnagrams(String s, String p) {
        int sLen = s.length(), pLen = p.length();
        if (sLen < pLen)
            return new ArrayList<Integer>();
        List<Integer> ans = new ArrayList<Integer>();
        int[] sCount = new int[26];
        int[] pCount = new int[26];
        for (int i = 0; i < pLen; ++i) {
            ++sCount[s.charAt(i) - 'a'];
            ++pCount[p.charAt(i) - 'a'];
        }
        if (Arrays.equals(sCount, pCount))
            ans.add(0);
        for (int i = 0; i < sLen - pLen; ++i) {
            --sCount[s.charAt(i) - 'a'];
            ++sCount[s.charAt(i + pLen) - 'a'];
            if (Arrays.equals(sCount, pCount))
                ans.add(i + 1);
        }
        return ans;
    }
}
```

第一个循环用于统计两个字符串中 **`pLen`部分** 字母的个数。第二个循环用于让字串`s`对应的滑动窗口向右移动一位，更新字母数量数据。最后，如果两个数组一样则表明符合条件。

在该方法的基础上，我们可以不再分别统计两个字串中字母的数量，转而统计每种字母数量的差，并额外引入变量 `differ` 来记录当前窗口和字符串`p`中数量不同的字母个数。

```java
public List<Integer> findAnagrams(String s, String p) {
    int sLen = s.length(), pLen = p.length(), temp;
    if (sLen < pLen) return new ArrayList<Integer>();
    List<Integer> ans = new ArrayList<Integer>();
    int[] count = new int[26];
    for (int i = 0; i < pLen; ++i) {
        ++count[s.charAt(i) - 'a'];
        --count[p.charAt(i) - 'a'];
    }
    int differ = 0;
    for (int j = 0; j < 26; ++j)
        if (count[j] != 0)
            ++differ;
    if (differ == 0)
        ans.add(0);
    for (int i = 0; i < sLen - pLen; ++i) {
        temp = count[s.charAt(i) - 'a'];
        if (temp == 1)
            --differ;
        else if (temp == 0)
            ++differ;
        --count[s.charAt(i) - 'a'];

        temp = count[s.charAt(i + pLen) - 'a'];
        if (temp == -1)
            --differ;
        else if (temp == 0)
            ++differ;
        ++count[s.charAt(i + pLen) - 'a'];
        if (differ == 0)
            ans.add(i + 1);
    }
    return ans;
}
```

其中的`count`数组存着串`s - p`的各个字母的差，其中每一个非0项都会让`differ` + 1。在`differ`赋值后，开始进行循环。`temp`变量用于获取当前的差值。首先是将左端划出窗口的情况，需要将`differ`中包含的情况给出清。然后是将右端划入窗口的情况，需要在`differ`中增加新差值。而循环体本身则演示滑动的过程。

### 子串

#### 和为K的子数组

给你一个整数数组 `nums` 和一个整数 `k` ，请你统计并返回 该数组中和为 `k` 的子数组的个数 。
子数组是数组中元素的连续非空序列。

{% note info %}
按照提示，使用哈希表进行操作。但哈希表上放什么是个值得考虑的问题，由于前缀和可能一样，所以这里放的是前缀和的值和出现的次数。

```java
class Solution {
    public int subarraySum(int[] nums, int k) {
        Map<Integer, Integer> map = new HashMap<>();
        map.put(0, 1);
        int sum = 0;
        int count = 0;
        for (int num : nums) {
            sum += num;
            if (map.containsKey(sum - k))
                count += map.get(sum - k);
            map.put(sum, map.getOrDefault(sum, 0) + 1);
        }
        return count;
    }
}
```

{% endnote %}

题解和上面的差不多

#### 滑动窗口最大值

给你一个整数数组 `nums`，有一个大小为 `k` 的滑动窗口从数组的最左侧移动到数组的最右侧。你只可以看到在滑动窗口内的 `k` 个数字。滑动窗口每次只向右移动一位。
返回 **滑动窗口中的最大值**。
示例：
    输入：`[1 3 -1 -3 5 3 6 7]`
    输出：`[3 3 5 5 6 7]`

| 滑动窗口的位置           | 最大值 |
|-|-|
| [1  3  -1] -3  5  3  6  7 | 3      |
| 1 [3  -1  -3] 5  3  6  7  | 3      |
| 1  3 [-1  -3  5] 3  6  7  | 5      |
| 1  3  -1 [-3  5  3] 6  7  | 5      |
| 1  3  -1  -3 [5  3  6] 7  | 6      |
| 1  3  -1  -3  5 [3  6  7] | 7      |

{% note info %}
滑动窗口就要注意其出来的数据和进来的数字。
勇敢一次次遍历，最后时间复杂度超过5%。

```java
class Solution {
    public int[] maxSlidingWindow(int[] nums, int k) {
        if (nums.length == 0) {
            return new int[0];
        }
        int[] ans = new int[nums.length - k + 1];
        int max = nums[0], maxIndex = 0;
        
        for (int i = 0; i < k; i++)
            if (max <= nums[i]) {
                max = nums[i];
                maxIndex = i;                
            }
        ans[0] = max;
        
        for (int i = k; i < nums.length; i++) {
            if (maxIndex == i - k) {
                max = nums[i - k + 1];
                maxIndex = i - k + 1;
                for (int j = i - k + 2; j <= i; j++)
                    if (max <= nums[j]) {
                        max = nums[j];
                        maxIndex = j;
                    }
            } else if (max <= nums[i]) {
                    max = nums[i];
                    maxIndex = i;
                }
            ans[i - k + 1] = max;
        }
        return ans;
    }
}
```

{% endnote %}

##### 优先队列

维护一个优先队列，初始时，将数组`nums`的前`k`个元素放入队列中，每次向右移动窗口是就把一个新的元素放入优先队列中。此时堆顶的元素就是堆中所有元素的最大值，但这个最大值可能并不在窗口中，这时候我们就要移除这个数据

```java
class Solution {
    public int[] maxSlidingWindow(int[] nums, int k) {
        int n = nums.length;
        PriorityQueue<int[]> pq = new PriorityQueue<int[]>(new Comparator<int[]>() {
            public int compare(int[] pair1, int[] pair2) {
                return pair1[0] != pair2[0] ? pair2[0] - pair1[0] : pair2[1] - pair1[1];
            }
        });
        for (int i = 0; i < k; ++i) {
            pq.offer(new int[]{nums[i], i});
        }
        int[] ans = new int[n - k + 1];
        ans[0] = pq.peek()[0];
        for (int i = k; i < n; ++i) {
            pq.offer(new int[]{nums[i], i});
            while (pq.peek()[1] <= i - k) {
                pq.poll();
            }
            ans[i - k + 1] = pq.peek()[0];
        }
        return ans;
    }
}
```

##### 单调队列

维护一个双向队列，存储所有还没有被移除的下标。这些下标按照从小到大的顺序存储。
当窗口向右移动时，我们需要把一个新元素放入队列中，若新元素大于队尾，就弹出队尾元素，直到空或队尾大于新元素。
此时的最大值可能在滑动窗口左边界的左侧，并且随着窗口向右移动，因此还需要不断从队首移除元素，直到队首元素在窗口中为止。
这种满足单调性的双端队列一般叫做单调队列。

```java
class Solution {
    public int[] maxSlidingWindow(int[] nums, int k) {
        int n = nums.length;
        Deque<Integer> deque = new LinkedList<Integer>();
        for (int i = 0; i < k; ++i) {
            while (!deque.isEmpty() && nums[i] >= nums[deque.peekLast()]) {
                deque.pollLast();
            }
            deque.offerLast(i);
        }

        int[] ans = new int[n - k + 1];
        ans[0] = nums[deque.peekFirst()];
        for (int i = k; i < n; ++i) {
            while (!deque.isEmpty() && nums[i] >= nums[deque.peekLast()]) {
                deque.pollLast();
            }
            deque.offerLast(i);
            while (deque.peekFirst() <= i - k) {
                deque.pollFirst();
            }
            ans[i - k + 1] = nums[deque.peekFirst()];
        }
        return ans;
    }
}
```

#### 最小覆盖子串

给你一个字符串 `s` 、一个字符串 `t` 。返回 `s` 中涵盖 `t` 所有字符的最小子串。如果 `s` 中不存在涵盖 `t` 所有字符的子串，则返回空字符串 `""` 。

示例 1：
    输入：`s = "ADOBECODEBANC", t = "ABC"`
    输出：`"BANC"`
    解释：最小覆盖子串 `"BANC"` 包含来自字符串 `t` 的 `'A'`、`'B'` 和 `'C'`。

示例 2:
    输入: `s = "a", t = "aa"`
    输出: `""`
    解释: `t` 中两个字符 `'a'` 均应包含在 `s` 的子串中，
    因此没有符合条件的子字符串，返回空字符串。

可以使用滑动窗口的方式来解决。维护两个指针，让右指针不断延申直到覆盖`t`中所有字母。然后让左指针运动，试图缩小范围。
如何判断包含了所有的字母？使用两个哈希表解决。

![图例](76_fig1.gif)

```java
class Solution {
    Map<Character, Integer> ori = new HashMap<Character, Integer>();
    Map<Character, Integer> cnt = new HashMap<Character, Integer>();

    public String minWindow(String s, String t) {
        int tLen = t.length();
        for (int i = 0; i < tLen; i++) {
            char c = t.charAt(i);
            ori.put(c, ori.getOrDefault(c, 0) + 1);
        }
        int l = 0, r = -1;
        int len = Integer.MAX_VALUE, ansL = -1, ansR = -1;
        int sLen = s.length();
        while (r < sLen) {
            ++r;
            if (r < sLen && ori.containsKey(s.charAt(r))) {
                cnt.put(s.charAt(r), cnt.getOrDefault(s.charAt(r), 0) + 1);
            }
            while (check() && l <= r) {
                if (r - l + 1 < len) {
                    len = r - l + 1;
                    ansL = l;
                    ansR = l + len;
                }
                if (ori.containsKey(s.charAt(l))) {
                    cnt.put(s.charAt(l), cnt.getOrDefault(s.charAt(l), 0) - 1);
                }
                ++l;
            }
        }
        return ansL == -1 ? "" : s.substring(ansL, ansR);
    }

    public boolean check() {
        Iterator iter = ori.entrySet().iterator(); 
        while (iter.hasNext()) { 
            Map.Entry entry = (Map.Entry) iter.next(); 
            Character key = (Character) entry.getKey(); 
            Integer val = (Integer) entry.getValue(); 
            if (cnt.getOrDefault(key, 0) < val) {
                return false;
            }
        } 
        return true;
    }
}
```

### 链表

#### 相交链表

给你两个单链表的头节点 `headA` 和 `headB` ，请你找出并返回两个单链表相交的起始节点。如果两个链表不存在相交节点，返回 `null` 。

![示例](getIntersectionNode-1.png)
    输入：`intersectVal = 8`, `listA = [4,1,8,4,5]`, `listB = [5,6,1,8,4,5]`, `skipA = 2`, `skipB = 3`
    输出：`Intersected at '8'`
    解释：相交节点的值为 `8` （注意，如果两个链表相交则不能为 0）。从各自的表头开始算起，链表 `A` 为 `[4,1,8,4,5]`，链表 B 为 `[5,6,1,8,4,5]`。在 A 中，相交节点前有 2 个节点；在 B 中，相交节点前有 3 个节点。
    - 请注意相交节点的值不为 1，因为在链表 A 和链表 B 之中值为 1 的节点 (A 中第二个节点和 B 中第三个节点) 是不同的节点。换句话说，它们在内存中指向两个不同的位置，而链表 A 和链表 B 中值为 8 的节点 (A 中第三个节点，B 中第四个节点) 在内存中指向相同的位置。

##### 哈希集合

先将 `headA` 中的节点加入哈希集合中，再遍历链表 `headB`，然后将 `headB` 中的节点与表中的进行比较。

```java
public class Solution {
    public ListNode getIntersectionNode(ListNode headA, ListNode headB) {
        Set<ListNode> visited = new HashSet<ListNode>();
        ListNode temp = headA;
        while (temp != null) {
            visited.add(temp);
            temp = temp.next;
        }
        temp = headB;
        while (temp != null) {
            if (visited.contains(temp)) {
                return temp;
            }
            temp = temp.next;
        }
        return null;
    }
}
```

##### 双指针

先判空，若二者均为非空，则在两个链表头创建两个指针 `pA` 和 `pB`。然后每步操作同时更新指针 `pA` 和 `pB`，若均不为空则移动到下一节点；一方为空则将该指针放到另一条的头部；指向同一节点则指向该节点；均为空则指向空。

设 `headA` 不相交部分长度为 $a$，`headB` 部分不相交部分长度为 $b$，二者相交部分为 $c$。若二者相交，一开始双方会同时走向相交节点(若 $a=b$)，或者分别走向链表尾，并走向另一条链表，而后者二者均需走$a+b+c$的长度碰到交汇点。若二者不相交，则在各自走了$a+c+b+c=a+b+2c$的长度下同时走向空值，返回`null`。

```java
public class Solution {
    public ListNode getIntersectionNode(ListNode headA, ListNode headB) {
        if (headA == null || headB == null)
            return null;
        ListNode pA = headA, pB = headB;
        while (pA != pB) {
            pA = pA == null ? headB : pA.next;
            pB = pB == null ? headA : pB.next;
        }
        return pA;
    }
}
```

{% note success %}
错的人就算走过了对方的路也还是会错过😔 这题我希望大家都返回`true`
<p align="right">——某神评</p>
{% endnote %}

#### **反转链表**

给你单链表的头节点 head ，请你反转链表，并返回反转后的链表。

示例：
![示例](rev1ex1.jpg)
    输入：`head = [1,2,3,4,5]`
    输出：`[5,4,3,2,1]`

##### 迭代

头插法创建新链表。

```java
class Solution {
    public ListNode reverseList(ListNode head) {
        ListNode prev = null; // 新链表的头部
        ListNode curr = head; // 旧链表的头部
        while (curr != null) {
            ListNode next = curr.next; // 要动的节点的 next
            curr.next = prev;
            prev = curr;
            curr = next;
        }
        return prev;
    }
}
```

##### 递归

相比迭代的从头来过，这个只是逆转了箭头的方向

```java
class Solution {
    public ListNode reverseList(ListNode head) {
        if (head == null || head.next == null) {
            return head;
        }
        ListNode newHead = reverseList(head.next);
        head.next.next = head;
        head.next = null;
        return newHead;
    }
}
```

##### 指定区间的情况 (原题: 反转链表 II)

[详见视频](https://www.bilibili.com/video/BV1sd4y1x7KN)

```java
class Solution {
    public ListNode reverseBetween(ListNode head, int left, int right) {
        ListNode dummy = new ListNode(0, head);
        ListNode p0 = dummy;
        // 找到需要开始反转的前一个节点
        for (int i = 0; i < left - 1; i++) {
            p0 = p0.next;
        }

        ListNode pre = null; // 新头节点
        ListNode cur = p0.next; // 旧头节点
        for (int i = 0; i < right - left + 1; i++) {
            ListNode nxt = cur.next;
            cur.next = pre;
            pre = cur;
            cur = nxt;
        }

        // dummy 节点的下一个节点即现在的末尾节点, 其 next 应该指向循环外的末尾
        p0.next.next = cur;
        // dummy 节点的下一个节点应该是以前的末尾节点
        p0.next = pre;
        return dummy.next;
    }
}
```

#### 回文链表

给你一个单链表的头节点 `head` ，请你判断该链表是否为回文链表。如果是，返回 `true` ；否则，返回 `false` 。
示例：
![示例](pal1linked-list.jpg)
    输入：`head = [1,2,2,1]`
    输出：`true`

{% note info %}
C++摆烂版，全部用栈。压一半，奇数个弹出中间那个，再比较一半。虽然比较慢但是很好懂（废话）

```cpp
class Solution {
public:
    bool isPalindrome(ListNode* head) {
        int counter = 0;
        stack<int> s;
        ListNode *temp = head;
        for(ListNode *pointer = head; pointer != nullptr; pointer = pointer->next, counter++);
        for(int i = 0; i < counter / 2; temp = temp->next, i++)
            s.push(temp->val);
        if(counter % 2)
            temp = temp->next;
        for(;temp != nullptr && !s.empty(); temp = temp->next)
            if(s.top() != temp->val)
                return false;
            else
                s.pop();
        if(!s.empty())
            return false;
        return true;
    }
};
```

{% endnote %}

##### 将值复制到数组中后用双指针法

```java
class Solution {
    public boolean isPalindrome(ListNode head) {
        List<Integer> vals = new ArrayList<Integer>();
        int front = 0, back = vals.size() - 1;  
        for(ListNode node = head; node != null; node = node.next)
            vals.add(currentNode.val);
        while (front < back) {
            if (!vals.get(front).equals(vals.get(back)))
                return false;
            front++;
            back--;
        }
        return true;
    }
}
```

顾名思义，这里不分析了，太狂暴了。

##### 递归

该方法可以以一种优雅的形式解决单向链表不能倒查的问题。

```java
class Solution {
    private ListNode frontPointer;

    private boolean recursivelyCheck(ListNode currentNode) {
        if (currentNode != null) {
            if (!recursivelyCheck(currentNode.next))
                return false;
            if (currentNode.val != frontPointer.val)
                return false;
            frontPointer = frontPointer.next;
        }
        return true;
    }

    public boolean isPalindrome(ListNode head) {
        frontPointer = head;
        return recursivelyCheck(head);
    }
}
```

`frontPointer`变量存储前面的值，递归的 `currentNode` 部分存储后面的值。若前面的`false`则传递下去，若二者值不相等也返回`false`。`frontPointer`通过`next`赋值实现迭代，`currentNode`部分通过递归的返回部分实现往回迭代。

#### 环形链表

给你一个链表的头节点 `head` ，判断链表中是否有环。

如果链表中有某个节点，可以通过连续跟踪 `next` 指针再次到达，则链表中存在环。 为了表示给定链表中的环，评测系统内部使用整数 pos 来表示链表尾连接到链表中的位置（索引从 0 开始）。注意：`pos` 不作为参数进行传递 。仅仅是为了标识链表的实际情况。

如果链表中存在环 ，则返回 `true` 。 否则，返回 `false` 。

示例：
![示例](circularlinkedlist.png)
    输入：`head = [3,2,0,-4], pos = 1`
    输出：`true`
    解释：链表中有一个环，其尾部连接到第二个节点。

##### 哈希表

```java
public class Solution {
    public boolean hasCycle(ListNode head) {
        Set<ListNode> seen = new HashSet<ListNode>();
        while (head != null) {
            if (!seen.add(head))
                return true;
            head = head.next;
        }
        return false;
    }
}
```

如果加不了就是已经加过了，遇到环了。

##### 快慢指针

此方法又叫 “Floyd判图算法”，又叫龟兔赛跑算法。快指针一次两步，慢指针一次一步。若无环则慢指针永远碰不上快指针；若有环则二者都会在环路中转圈，当二者路程差刚好是环长度的倍数时就是二者相遇的时候。

```java
public class Solution {
    public boolean hasCycle(ListNode head) {
        if (head == null || head.next == null)
            return false;
        ListNode slow = head, fast = head.next;
        while (slow != fast) {
            if (fast == null || fast.next == null)
                return false;
            slow = slow.next;
            fast = fast.next.next;
        }
        return true;
    }
}
```

#### 环形链表II

给定一个链表的头节点  `head` ，返回链表开始入环的第一个节点。 如果链表无环，则返回 `null。`

如果链表中有某个节点，可以通过连续跟踪 `next` 指针再次到达，则链表中存在环。 注意：此处的`pos` 不作为参数进行传递，仅仅是为了标识链表的实际情况。
不允许修改 链表。

示例：
![示例](circularlinkedlist.png)
    输入：`head = [3,2,0,-4], pos = 1`
    输出：返回索引为 1 的链表节点
    解释：链表中有一个环，其尾部连接到第二个节点。

{% note info %}
可以把上一题的哈希表法改一改

```java
public class Solution {
    public boolean hasCycle(ListNode head) {
        Set<ListNode> seen = new HashSet<ListNode>();
        while (head != null) {
            if (!seen.add(head))
                return true;
            head = head.next;
        }
        return false;
    }
}
```

{% endnote %}

用快慢指针改一改同样能实现定位环的效果。

![图例](142_fig1.png)

设`slow`指针走了 `b` 距离与 `fast` 相遇，此时，`fast`指针已经走了`n`圈，此时快指针走过的总距离为

$$
a+n(b+c)+b=a+(n+1)b+nc
$$

由于$v_{fast}=2v_{slow}$，因此有

$$
\underbrace{a+(n+1)b+nc}_{\text{快指针}}=\underbrace{2(a+b)}_{\text{慢指针}}⟹a=c+(n−1)(b+c)
$$

但对于指针而言，绕圈圈数可以忽略。因此最后简化成

$$
a=c
$$

于是，在二者相遇时，我们再用一个指针指向头部，并与slow指针同步走动，二者相遇的位置即是环开始点。

```java
class Solution {
public:
    ListNode *detectCycle(ListNode *head) {
        ListNode *slow = head, *fast = head;
        while (fast != nullptr) {
            slow = slow->next;
            if (fast->next == nullptr)
                return nullptr;
            fast = fast->next->next;
            if (fast == slow) {
                ListNode *ptr = head;
                while (ptr != slow) {
                    ptr = ptr->next;
                    slow = slow->next;
                }
                return ptr;
            }
        }
        return nullptr;
    }
};
```

#### 合并两个有序链表

将两个升序链表合并为一个新的 升序 链表并返回。新链表是通过拼接给定的两个链表的所有节点组成的。

示例：
![示例](merge_ex1.jpg)
    输入：l1 = [1,2,4], l2 = [1,3,4]
    输出：[1,1,2,3,4,4]

{% note info %}
可以把链表2合并到链表1上。

```cpp
class Solution
{
public:
    ListNode *mergeTwoLists(ListNode *list1, ListNode *list2)
    {
        ListNode *temp = list2, *swap = list2, *head = list1;
        if(list1 == nullptr || list2 == nullptr)
            return list1 == nullptr ? list2 : list1;
        if (list2->val < list1->val)
        {
            swap = list2, head = list2;
            while (swap->next != nullptr && swap->next->val < list1->val)
                swap = swap->next, temp = temp->next;
            temp = temp->next;
            swap->next = list1;
        }

        for (ListNode *p = list1; p->next != nullptr && temp != nullptr; p = p->next)
        {
            if (temp != nullptr && temp->val >= p->val && temp->val <= p->next->val)
            {
                swap = temp;
                temp = temp->next;
                swap->next = p->next;
                p->next = swap;
            }
        }
        if (temp != nullptr)
        {
            ListNode *p = list1;
            for (; p->next != nullptr; p = p->next);
            p->next = temp;
        }
        return head;
    }
};
```

指定两个指针`p1`和`p2`，分别指向两个链表。若`p2 >= p1`，则说明是时候插入了，于是在`p1->next`处进行插入。然后对余下部分循环插入。
{% endnote %}

##### 递归

定义两个链表的merge操作如下（忽略空链表的情况）

$$
\begin{cases}
list_1[0]+merge(list_1[1:],list_{2})\quad list_1[0]<list_2[0] \\\\
list_2[0]+merge(list_1,list_2[1:])\quad \text{otherwise}
\end{cases}
$$

也就是说，两个链表头部值较小的一个节点与剩下元素的 `merge` 操作结果合并。

```java
class Solution {
    public ListNode mergeTwoLists(ListNode l1, ListNode l2) {
        if (l1 == null) {
            return l2;
        } else if (l2 == null) {
            return l1;
        } else if (l1.val < l2.val) {
            l1.next = mergeTwoLists(l1.next, l2);
            return l1;
        } else {
            l2.next = mergeTwoLists(l1, l2.next);
            return l2;
        }
    }
}
```

哪个值更小，就把哪个放进递归里面，当最后返回时，已经帮排好序了。

##### 迭代

```java
class Solution {
    public ListNode mergeTwoLists(ListNode l1, ListNode l2) {
        ListNode prehead = new ListNode(-1);
        ListNode prev = prehead;
        while (l1 != null && l2 != null) {
            if (l1.val <= l2.val) {
                prev.next = l1;
                l1 = l1.next;
            } else {
                prev.next = l2;
                l2 = l2.next;
            }
            prev = prev.next;
        }
        prev.next = l1 == null ? l2 : l1;
        return prehead.next;
    }
}
```

#### 两数相加

给你两个 **非空** 的链表，表示两个非负的整数。它们每位数字都是按照 **逆序** 的方式存储的，并且每个节点只能存储 **一位** 数字。
请你将两个数相加，并以相同形式返回一个表示和的链表。
你可以假设除了数字 `0` 之外，这两个数都不会以 `0` 开头。

示例：
![示例](addtwonumber1.jpg)
    输入：`l1 = [2,4,3], l2 = [5,6,4]`
    输出：`[7,0,8]`
    解释：`342 + 465 = 807`.

这个和数电的ALU计算器类似，一位位计算他们的值并存储进位。以下是题解的模拟法

```java
class Solution {
public:
    ListNode* addTwoNumbers(ListNode* l1, ListNode* l2) {
        ListNode *head = nullptr, *tail = nullptr;
        int carry = 0;
        while (l1 || l2) {
            int n1 = l1 ? l1->val: 0;
            int n2 = l2 ? l2->val: 0;
            int sum = n1 + n2 + carry;
            if (!head)
                head = tail = new ListNode(sum % 10);
            else {
                tail->next = new ListNode(sum % 10);
                tail = tail->next;
            }
            carry = sum / 10;
            if (l1)
                l1 = l1->next;
            if (l2)
                l2 = l2->next;
        }
        if (carry > 0)
            tail->next = new ListNode(carry);
        return head;
    }
};
```

确实是比自己写的简洁。

#### 删除链表的倒数第N个节点

给你一个链表，删除链表的倒数第 `n` 个结点，并且返回链表的头结点。
示例：
    输入：`head = [1,2,3,4,5], n = 2`
    输出：`[1,2,3,5]`

题目的提示给得很明显了，可以使用双指针，让两个指针之间的距离保持n步。然后慢指针就是要删去的值。

题解如下

```java
class Solution {
    public ListNode removeNthFromEnd(ListNode head, int n) {
        ListNode dummy = new ListNode(0, head);
        int length = getLength(head);
        ListNode cur = dummy;
        for (int i = 1; i < length - n + 1; ++i) {
            cur = cur.next;
        }
        cur.next = cur.next.next;
        ListNode ans = dummy.next;
        return ans;
    }

    public int getLength(ListNode head) {
        int length = 0;
        while (head != null) {
            ++length;
            head = head.next;
        }
        return length;
    }
}
```

{% note info %}
又臭又长，不如看看我这个

```java
class Solution {
    public ListNode removeNthFromEnd(ListNode head, int n) {
        ListNode p1 = head, p2 = head;
        int length;
        for(length = 0; p1 != null; p1 = p1.next, length++)
            p2 = length > n ? p2.next : p2;
        if(length == n)
            return head.next;
        p2.next = p2.next.next;
        return head;
    }
}
```

在遍历的时候顺便把长度算出来就行了。
{% endnote %}

#### 两两交换链表中的节点

给你一个链表，两两交换其中相邻的节点，并返回交换后链表的头节点。你必须在不修改节点内部的值的情况下完成本题（即，只能进行节点交换）。

示例：
    输入：`head = [1,2,3,4]`
    输出：`[2,1,4,3]`

##### 迭代

```java
class Solution {
    public ListNode swapPairs(ListNode head) {
        ListNode dummyHead = new ListNode(0);
        dummyHead.next = head;
        ListNode temp = dummyHead;
        while (temp.next != null && temp.next.next != null) {
            ListNode node1 = temp.next;
            ListNode node2 = temp.next.next;
            temp.next = node2;
            node1.next = node2.next;
            node2.next = node1;
            temp = node1;
        }
        return dummyHead.next;
    }
}
```

{% note info %}
当然也可以不声明这个头节点，让`head`专事专办也可以

```java
class Solution {
    public ListNode swapPairs(ListNode head) {
        if(head == null || head.next == null)
            return head;
        ListNode left = head, right = head.next, front = head, ans = right;
        left.next = right.next;
        right.next = left;
        while(front.next != null && front.next.next != null) {
            left = front.next;
            right = left.next;
            front.next = right;
            left.next = right.next;
            right.next = left;
            front = left;
        }
        return ans;
    }
}
```

{% endnote %}

#### **K个一组翻转链表**

{% note danger %}
美团后台开发 - 暑期实习, 一面.
{% endnote %}

给你链表的头节点 `head` ，每 `k` 个节点一组进行翻转，请你返回修改后的链表。
`k` 是一个正整数，它的值小于或等于链表的长度。如果节点总数不是 `k` 的整数倍，那么请将最后剩余的节点保持原有顺序。
你不能只是单纯的改变节点内部的值，而是需要实际进行节点交换。

示例：
    输入：`head = [1,2,3,4,5], k = 2`
    输出：`[2,1,4,3,5]`

中间是[逆转链表](#指定区间的情况-原题-反转链表-ii)的过程，只要放个循环就行. [详见视频](https://www.bilibili.com/video/BV1sd4y1x7KN)

```java
class Solution {
    public ListNode reverseKGroup(ListNode head, int k) {
        // 统计节点个数
        int n = 0;
        for (ListNode cur = head; cur != null; cur = cur.next) {
            n++;
        }

        ListNode dummy = new ListNode(0, head);
        ListNode p0 = dummy;
        ListNode pre = null; // 新头节点
        ListNode cur = p0.next; // 旧头节点

        for(; n >= k; n -= k) {
            for (int i = 0; i < right - left + 1; i++) {
                ListNode nxt = cur.next;
                cur.next = pre;
                pre = cur;
                cur = nxt;
            }
            ListNode next = p0.next;
            // dummy 节点的下一个节点即现在的末尾节点, 其 next 应该指向循环外的末尾
            p0.next.next = cur;
            // dummy 节点的下一个节点应该是以前的末尾节点
            p0.next = pre;
            // 与指定位置不同, 此处需要将 dummy 指定为现在的末尾节点
            p0 = next;
        }
        return dummy.next;
    }
}
```

#### 随机链表的复制

给你一个长度为 `n` 的链表，每个节点包含一个额外增加的随机指针 `random` ，该指针可以指向链表中的任何节点或空节点。
构造这个链表的*深拷贝*[^1]。 深拷贝应该正好由 n 个 全新 节点组成，其中每个新节点的值都设为其对应的原节点的值。新节点的 `next` 指针和 `random` 指针也都应指向复制链表中的新节点，并使原链表和复制链表中的这些指针能够表示相同的链表状态。复制链表中的指针都不应指向原链表中的节点 。
例如，如果原链表中有 `X` 和 `Y` 两个节点，其中 `X.random --> Y` 。那么在复制链表中对应的两个节点 `x` 和 `y` ，同样有 `x.random --> y` 。
返回复制链表的头节点。

提示中显示的做法是在原链表每个节点后面新建一个节点，这样就可以直接复制原节点的`random`值了。

题解的做法如下

```java
class Solution {
    public Node copyRandomList(Node head) {
        if (head == null) {
            return null;
        }
        for (Node node = head; node != null; node = node.next.next) {
            Node nodeNew = new Node(node.val);
            nodeNew.next = node.next;
            node.next = nodeNew;
        }
        for (Node node = head; node != null; node = node.next.next) {
            Node nodeNew = node.next;
            nodeNew.random = (node.random != null) ? node.random.next : null;
        }
        Node headNew = head.next;
        for (Node node = head; node != null; node = node.next) {
            Node nodeNew = node.next;
            node.next = node.next.next;
            nodeNew.next = (nodeNew.next != null) ? nodeNew.next.next : null;
        }
        return headNew;
    }
}
```

[^1]: 深拷贝出来的两个链表有3个特征：1. 原来的值全部拷贝；2. 保证拷贝后的链表和原来的链表不重叠（`return head`是不行的）；3. 原来的链表必须保持原样（删去原来链表一部分的行为是不行的）。

#### 排序链表

给好链表头结点，对链表进行排序

##### 自顶向下归并排序

找到链表的中点，以中点为分界，将链表拆分为两个子链表，对两个子链表进行排序，最后按照[上一道题](#合并两个有序链表)的方法合并链表。当然拆分过程可以递归实现

```java
class Solution {
    public ListNode sortList(ListNode head) {
        return sortList(head, null);
    }

    public ListNode sortList(ListNode head, ListNode tail) {
        if (head == null) {
            return head;
        }
        if (head.next == tail) {
            head.next = null;
            return head;
        }
        ListNode slow = head, fast = head;
        while (fast != tail) {
            slow = slow.next;
            fast = fast.next;
            if (fast != tail) {
                fast = fast.next;
            }
        }
        ListNode mid = slow;
        ListNode list1 = sortList(head, mid);
        ListNode list2 = sortList(mid, tail);
        ListNode sorted = merge(list1, list2);
        return sorted;
    }

    public ListNode merge(ListNode head1, ListNode head2) {
        ListNode dummyHead = new ListNode(0);
        ListNode temp = dummyHead, temp1 = head1, temp2 = head2;
        while (temp1 != null && temp2 != null) {
            if (temp1.val <= temp2.val) {
                temp.next = temp1;
                temp1 = temp1.next;
            } else {
                temp.next = temp2;
                temp2 = temp2.next;
            }
            temp = temp.next;
        }
        if (temp1 != null) {
            temp.next = temp1;
        } else if (temp2 != null) {
            temp.next = temp2;
        }
        return dummyHead.next;
    }
}
```

##### 自底向上归并排序

1. 用`subLength`表示每次需要排序的子链表长度，初始时`subLength = 1`
2. 每次将链表拆分成若干个长度为`subLength`的子链表，按照每两个子链表一组进行合并，[合并方法仍然是这个](#合并两个有序链表)
3. 重复上面的步骤

```java
class Solution {
    public ListNode sortList(ListNode head) {
        if (head == null) {
            return head;
        }
        int length = 0;
        ListNode node = head;
        while (node != null) {
            length++;
            node = node.next;
        }
        ListNode dummyHead = new ListNode(0, head);
        for (int subLength = 1; subLength < length; subLength <<= 1) {
            ListNode prev = dummyHead, curr = dummyHead.next;
            while (curr != null) {
                ListNode head1 = curr;
                for (int i = 1; i < subLength && curr.next != null; i++) {
                    curr = curr.next;
                }
                ListNode head2 = curr.next;
                curr.next = null;
                curr = head2;
                for (int i = 1; i < subLength && curr != null && curr.next != null; i++) {
                    curr = curr.next;
                }
                ListNode next = null;
                if (curr != null) {
                    next = curr.next;
                    curr.next = null;
                }
                ListNode merged = merge(head1, head2);
                prev.next = merged;
                while (prev.next != null) {
                    prev = prev.next;
                }
                curr = next;
            }
        }
        return dummyHead.next;
    }

    public ListNode merge(ListNode head1, ListNode head2) {
        ListNode dummyHead = new ListNode(0);
        ListNode temp = dummyHead, temp1 = head1, temp2 = head2;
        while (temp1 != null && temp2 != null) {
            if (temp1.val <= temp2.val) {
                temp.next = temp1;
                temp1 = temp1.next;
            } else {
                temp.next = temp2;
                temp2 = temp2.next;
            }
            temp = temp.next;
        }
        if (temp1 != null) {
            temp.next = temp1;
        } else if (temp2 != null) {
            temp.next = temp2;
        }
        return dummyHead.next;
    }
}
```

#### LRU缓存

请你设计并实现一个满足 **LRU** (最近最少使用) 缓存约束的数据结构。
实现 LRUCache 类：

- `LRUCache(int capacity)` 以 **正整数** 作为容量 `capacity` 初始化 `LRU` 缓存
- `int get(int key)` 如果关键字 `key` 存在于缓存中，则返回关键字的值，否则返回 `-1` 。
- `void put(int key, int value)` 如果关键字 `key` 已经存在，则变更其数据值 value ；如果不存在，则向缓存中插入该组 `key-value` 。如果插入操作导致关键字数量超过 `capacity` ，则应该 **逐出** 最久未使用的关键字。

函数 `get` 和 `put` 必须以 $O(1)$ 的平均时间复杂度运行。

{% note info %}
难点是必需要在$O(1)$时间复杂度做好`get`和`put`操作。这就要求不能用数组之类的结构了，使用双向链表明显是最便捷的：用链表的位置表明最近的使用情况。当达到容量大小时直接删除末位的链表即可。而链表的查找可以交给哈希表解决。
但这又导致了新的问题。当进行`get`或`put`操作时，该缓存块被使用，因此需要把该节点运到头节点处，这也是最难办的部分。

此处将其分为两个部分：要么尾部没有节点，要么尾部有节点。

{% endnote %}

#### 合并K个排序链表

给你一个链表数组，每个链表都已经按升序排列。
请你将所有链表合并到一个升序链表中，返回合并后的链表。

以[前面的题目为基础](#合并两个有序链表)，可以一个个链表合并。更快的办法是用分治的办法进行合并。在第一轮合并后，$k$个链表被合并为了$k/2$和链表，以此类推，直到只剩一条

![图例](6f70a6649d2192cf32af68500915d84b476aa34ec899f98766c038fc9cc54662-image.png)

```java
class Solution {
    class Status implements Comparable<Status> {
        int val;
        ListNode ptr;

        Status(int val, ListNode ptr) {
            this.val = val;
            this.ptr = ptr;
        }

        public int compareTo(Status status2) {
            return this.val - status2.val;
        }
    }

    PriorityQueue<Status> queue = new PriorityQueue<Status>();

    public ListNode mergeKLists(ListNode[] lists) {
        for (ListNode node: lists)
            if (node != null)
                queue.offer(new Status(node.val, node));
        ListNode head = new ListNode(0);
        ListNode tail = head;
        while (!queue.isEmpty()) {
            Status f = queue.poll();
            tail.next = f.ptr;
            tail = tail.next;
            if (f.ptr.next != null)
                queue.offer(new Status(f.ptr.next.val, f.ptr.next));
        }
        return head.next;
    }
}
```

