---
title: leetcode热题100官方题解 - 6
date: 2025-08-22 15:29:00
tags: [算法, 贪心, 二分, 图论]
category: leetcode
---

### 贪心

#### 买卖股票的最佳时机

给定一个数组 `prices` ，它的第 `i` 个元素 `prices[i]` 表示一支给定股票第 `i` 天的价格。

你只能选择 **某一天** 买入这只股票，并选择在 **未来的某一个不同的日子** 卖出该股票。设计一个算法来计算你所能获取的最大利润。

返回你可以从这笔交易中获取的最大利润。如果你不能获取任何利润，返回 `0` 。

示例：
    输入：`[7,1,5,3,6,4]`
    输出：`5`
    解释：在第 2 天（股票价格 = 1）的时候买入，在第 5 天（股票价格 = 6）的时候卖出，最大利润 = 6-1 = 5 。
        注意利润不能是 7-1 = 6, 因为卖出价格需要大于买入价格；同时，你不能在买入前卖出股票。

{% note info %}
可以使用动态规划，用`dp`数组存储在某个索引前最大的值

```java
class Solution {
    public int maxProfit(int[] prices) {
        int[] dp = new int[prices.length];
        int min = prices[0];
        for(int i = 1; i < prices.length; i++) {
            min = Math.min(prices[i], min);
            dp[i] = Math.max(dp[i - 1], prices[i] - min > 0 ? prices[i] - min : 0);
        }
        return dp[prices.length - 1];
    }
}
```

但其实我们可以发现，在这个状态转移方程中最大值的选取只与前一个值有关，于是可以简化成只用一个数存储

```java
class Solution {
    public int maxProfit(int[] prices) {
        int min = prices[0], ans = -1;
        for(int i : prices) {
            min = Math.min(i, min);
            ans = Math.max(i - min, ans);
        }
        return ans > 0 ? ans : 0;
    }
}
```

{% endnote %}

在注释的题解2，其实可以换个理解方式：用前面最小的值比对后面最大的值

![就是用山峰减去山谷](cc4ef55d97cfef6f9215285c7573027c4b265c31101dd54e8555a7021c95c927-file_1555699418271.png)

#### 跳跃游戏

给你一个非负整数数组 `nums` ，你最初位于数组的 **第一个下标** 。数组中的每个元素代表你在该位置可以跳跃的最大长度。
判断你是否能够到达最后一个下标，如果可以，返回 `true` ；否则，返回 `false` 。

示例 1：
    输入：`nums = [2,3,1,1,4]`
    输出：`true`
    解释：可以先跳 1 步，从下标 0 到达下标 1, 然后再从下标 1 跳 3 步到达最后一个下标。

示例 2：
    输入：`nums = [3,2,1,0,4]`
    输出：`false`
    解释：无论怎样，总会到达下标为 3 的位置。但该下标的最大跳跃长度是 0 ， 所以永远不可能到达最后一个下标。

{% note info %}
维护一个数`max`，表示当前索引下能跳的最大格数，如果没到最后就变成0了就表示跳不出来。

```java
class Solution {
    public boolean canJump(int[] nums) {
        int max = nums[0];
        for(int i = 0; i < nums.length; i++) {
            max = Math.max(nums[i], max - 1);
            if(max == 0 && i != nums.length - 1)
                return false;             
        }
        return true;
    }
}
```

{% endnote %}

#### 跳跃游戏II

给定一个长度为 `n` 的 `0` 索引整数数组 `nums`。初始位置为 `nums[0]`。

每个元素 `nums[i]` 表示从索引 `i` 向后跳转的最大长度。换句话说，如果你在索引 `i` 处，你可以跳转到任意 `(i + j)` 处：

- `0 <= j <= nums[i]`
- `i + j < n`

返回到达 `n - 1` 的最小跳跃次数。测试用例保证可以到达 `n - 1`。

示例:
    输入: `nums = [2,3,1,1,4]`
    输出: `2`
    解释: 跳到最后一个位置的最小跳跃数是 2。
        从下标为 0 跳到下标为 1 的位置，跳 1 步，然后跳 3 步到达数组的最后一个位置。

{% note info %}
也可以使用动态规划做，虽然效率不高

```java
class Solution {
    public int jump(int[] nums) {
        int dp[] = new int[nums.length];
        Arrays.fill(dp, nums.length);
        dp[0] = 0;
        for(int i = 0; i < nums.length; i++) {
            if(nums[i] == 0)
                continue;
            for(int j = 1; j <= nums[i] && i + j < nums.length; j++)
                dp[i + j] = Math.min(dp[i + j], dp[i] + 1);
        }
        return dp[nums.length - 1];
    }
}
```

{% endnote %}

我们可以“贪心”地选择距离最后一个位置最远的那个位置，找到倒数第一步后再选第二步，直到找到数组的开始位置。

```java
class Solution {
    public int jump(int[] nums) {
        int position = nums.length - 1;
        int steps = 0;
        while (position > 0)
            for (int i = 0; i < position; i++)
                if (i + nums[i] >= position) {
                    position = i;
                    steps++;
                    break;
                }
        return steps;
    }
}
```

又或者可以遍历，“贪心”地进行正向寻找，每次找到可达的最远位置

```java
class Solution {
    public int jump(int[] nums) {
        int length = nums.length;
        int end = 0;
        int maxPosition = 0; 
        int steps = 0;
        for (int i = 0; i < length - 1; i++) {
            maxPosition = Math.max(maxPosition, i + nums[i]); 
            if (i == end) {
                end = maxPosition;
                steps++;
            }
        }
        return steps;
    }
}
```

{% note success %}
说人话：end 就是你在上一次更新end的时候那个点能跳到的最远距离，要想走更远，得再跳一次了（step ++）
<p align = "right">——某评论</p>
{% endnote %}

#### 划分字母区间

给你一个字符串 `s` 。我们要把这个字符串划分为尽可能多的片段，同一字母最多出现在一个片段中。例如，字符串 `"ababcc"` 能够被分为 `["abab", "cc"]`，但类似 `["aba", "bcc"]` 或 `["ab", "ab", "cc"]` 的划分是非法的。
注意，划分结果需要满足：将所有划分结果按顺序连接，得到的字符串仍然是 `s` 。
返回一个表示每个字符串片段的长度的列表。

示例：
    输入：`s = "ababcbacadefegdehijhklij"`
    输出：`[9,7,8]`
    解释：
    划分结果为 `"ababcbaca"`、`"defegde"`、`"hijhklij"` 。
    每个字母最多出现在一个片段中。
    像 `"ababcbacadefegde"`, `"hijhklij"` 这样的划分是错误的，因为划分的片段数较少。

{% note info %}
这次的提示确实只是提示，没有给太多信息，只提示了可以将字母最后一次出现的位置记录下来。但如何贪心出来就不清楚了。
按照贪心，一次字符串需要包含最少的字母，因此需要将到最后一次出现字母的子串包圆。而这个“最后一次”又是需要随着字母增加不断更新维护的

```java
class Solution {
    public List<Integer> partitionLabels(String s) {
        Map<Character, Integer> map = new HashMap<>();
        List<Integer> ans = new ArrayList<>();
        for(int i = 0; i < s.length(); i++)
            map.put(s.charAt(i), i);
        for(int i = 0, temp = 0, begin = -1; i < s.length(); i++) {
            temp = Math.max(temp, map.get(s.charAt(i)));
            if(i == temp) {
                ans.add(i - begin);
                begin = i;
            }
        }
        return ans;
    }
}
```

{% endnote %}

题解将上面的哈希表换成了字母数组`int[26]`，相比上面的代码能省不少时间。

### 二分

{% note success %}
注意二分中中间指针的规范写法应该为`mid = left + (right - left) / 2`，防止数组元素太多，导致`left + right`溢出。不过好像leetcode一般不会这么为难人。
{% endnote %}

#### 搜索插入位置

给定一个排序数组和一个目标值，在数组中找到目标值，并返回其索引。如果目标值不存在于数组中，返回它将会被按顺序插入的位置。
请必须使用时间复杂度为 $O(\log n)$ 的算法。

{% note info %}
很明显的二分了。但二分的细节很容易处理不好。比如要找的数字比初始的`left`小呢？比初始的`right`大呢？和某次遍历的`left`或`right`相等呢？为什么最后找不到返回的是`left`而不是其他？这都是需要思考的

```java
class Solution {
    public int searchInsert(int[] nums, int target) {
        int left = 0, right = nums.length - 1, mid = (left + right) / 2;
        while(left <= right) {
            if(target == nums[mid])
                return mid;
            else if(target > nums[mid])
                left = mid + 1;
            else
                right = mid - 1;
            mid = (left + right) / 2;
        }
        return left;
    }
}
```

{% endnote %}

- 若要找的数字比初始的`left`小，那么`mid`会一直往左到`left`的位置。最后会返回`left`。比`right`大的情况同理
- 若`left`或者`right`刚好就是要找的数，那么另一边会快速收敛。最后当三个指针都在同一位置时就可以了
- 结束循环后，出现了`left > right`的情况，此时的`left`就是第一个大于元素目标值的位置，当然就是这里了

#### 搜索二维矩阵

和[这道题](https://ivanclf.github.io/2025/08/18/leetcode-5/#%E6%90%9C%E7%B4%A2%E4%BA%8C%E5%8F%89%E7%9F%A9%E9%98%B5)的解法是一样的，这里不另外写了。但题解都是基于二分查找的（毕竟在二分这个分类下），其实不算高效。

#### 在排序数组中查找元素的第一个和最后一个位置

给你一个按照非递减顺序排列的整数数组 nums，和一个目标值 `target`。请你找出给定目标值在数组中的开始位置和结束位置。
如果数组中不存在目标值 `target，返回 [-1, -1]`。
你必须设计并实现时间复杂度为 $O(log n)$ 的算法解决此问题。

示例：
    输入：`nums = [5,7,7,8,8,10], target = 8`
    输出：`[3,4]`

{% note info %}
依然是普通的二分查找，只是不同之处在于，如果找到了，需要重置左右指针，再让左右指针向两边扩展，获取范围

```java
class Solution {
    public int[] searchRange(int[] nums, int target) {
        if(nums.length == 0)
            return new int[]{-1,-1};
        int left = 0, right = nums.length - 1, mid = (left + right) / 2;
        while(left <= right) {
            if(target == nums[mid]) {
                left = mid;
                right = mid;
                while(left > 0 && nums[left - 1] == nums[mid])
                    left--;
                while(right < nums.length - 1 && nums[right + 1] == nums[mid])
                    right++;
                return new int[]{left, right};
            } else if(target < nums[mid])
                right = mid - 1;
            else
                left = mid + 1;
            mid = (left + right) / 2;
        }
        return new int[]{-1,-1};
    }
}
```

{% endnote %}

上面的方法在极端状况下为$O(n)$（比如全部元素都是`target`的情况）。因此题解中有了一种更快的方法。

```java
class Solution {
    public int[] searchRange(int[] nums, int target) {
        int leftIdx = binarySearch(nums, target, true);
        int rightIdx = binarySearch(nums, target, false) - 1;
        if (leftIdx <= rightIdx && rightIdx < nums.length && nums[leftIdx] == target && nums[rightIdx] == target) {
            return new int[]{leftIdx, rightIdx};
        } 
        return new int[]{-1, -1};
    }

    public int binarySearch(int[] nums, int target, boolean lower) {
        int left = 0, right = nums.length - 1, ans = nums.length;
        while (left <= right) {
            int mid = (left + right) / 2;
            if (nums[mid] > target || (lower && nums[mid] >= target)) {
                right = mid - 1;
                ans = mid;
            } else {
                left = mid + 1;
            }
        }
        return ans;
    }
}
```

寻找第一个大于等于`target`的坐标和第一个小于等于`target`的坐标。若都等于的就返回无解情况。由于在`lower`为真的情况下，等于`target`的情况也会让`right`移动，因此最后出来的就是第一个小于等于`target`的坐标。但`lower`不为真的情况下，等于`target`归类到`else`类，让`left`移动了。

#### 搜索旋转排序数组

整数数组 `nums` 按升序排列，数组中的值 **互不相同** 。

在传递给函数之前，`nums` 在预先未知的某个下标 `k`（`0 <= k < nums.length`）上进行了 向左旋转，使数组变为 `[nums[k], nums[k+1], ..., nums[n-1], nums[0], nums[1], ..., nums[k-1]]`（下标 从 0 开始 计数）。例如， `[0,1,2,4,5,6,7]` 下标 3 上向左旋转后可能变为 `[4,5,6,7,0,1,2]` 。

给你 旋转后 的数组 nums 和一个整数 `target` ，如果 nums 中存在这个目标值 `target` ，则返回它的下标，否则返回 -`1` 。

你必须设计一个时间复杂度为 $O(\log n)$ 的算法解决此问题。

当我们将数组从中间分开成左右两部分的时候，一定有一部分的数组是有序的，因此我们可以在常规二分查找的时候查看当前`mid`为分割位置分割出来的两个部分`[l, mid]`和`[mid + 1, r]`哪个部分是有序的，并根据有序的那个部分确定我们应该如何改变二分查找的上下界。因为我们可以根据有序的那部分判断出`target`在不在那个部分：

- 若`[l, mid - 1]`是有序数组，且`target`的大小满足`[num[l], nums[mid]]`，那么我们应该将搜索范围缩小至`[l, mid - 1]`。否则在`[mid + 1, r]`中寻找。
- 若`[mid, r]`是有序数组，且`target`的大小满足`[nums[mid + 1], nums[r]]`，则我们应该将搜索范围缩小至`[mid + 1, r]`，否则在`[l, mid - 1]`中寻找。

```java
class Solution {
    public int search(int[] nums, int target) {
        int n = nums.length;
        if (n == 0)
            return -1;
        if (n == 1)
            return nums[0] == target ? 0 : -1;
        int l = 0, r = n - 1;
        while (l <= r) {
            int mid = (l + r) / 2;
            if (nums[mid] == target)
                return mid;
            if (nums[0] <= nums[mid]) {
                if (nums[0] <= target && target < nums[mid])
                    r = mid - 1;
                else
                    l = mid + 1;
            } else {
                if (nums[mid] < target && target <= nums[n - 1])
                    l = mid + 1;
                else
                    r = mid - 1;
            }
        }
        return -1;
    }
}
```

#### 寻找旋转排序数组中的最小值

给你一个元素值 **互不相同** 的数组 `nums` ，它原来是一个升序排列的数组，并按上述情形进行了多次旋转。请你找出并返回数组中的 **最小元素** 。
你必须设计一个时间复杂度为 $O(\log n)$ 的算法解决此问题。

按照提示，数组的第一个元素总是小于数组左半边的值，总是大于数组右半边的值。因此其中点的意义也有一定变化

- 若中点值比右指针小，则让右指针转移到中点这里
- 若中点值比左指针大，则让左指针转移到中点过一格

```java
class Solution {
    public int findMin(int[] nums) {
        int low = 0;
        int high = nums.length - 1;
        while (low < high) {
            int pivot = low + (high - low) / 2;
            if (nums[pivot] < nums[high])
                high = pivot;
            else
                low = pivot + 1;
        }
        return nums[low];
    }
}
```

{% note success %}
这个左右`+1`的细微差别，可真是tmd小巧思呢。
{% endnote %}

#### 寻找两个正序数组的中位数

给定两个大小分别为 `m` 和 `n` 的正序（从小到大）数组 `nums1` 和 `nums2`。请你找出并返回这两个正序数组的 **中位数** 。

算法的时间复杂度应该为 $O(\log (m+n))$ 。

{% note info %}
我管你这那的

```java
class Solution {
    public double findMedianSortedArrays(int[] nums1, int[] nums2) {
        int[] result = new int[nums1.length + nums2.length];
        System.arraycopy(nums1, 0, result, 0, nums1.length);
        System.arraycopy(nums2, 0, result, nums1.length, nums2.length);
        Arrays.sort(result);
        return result.length % 2 == 1 ? result[result.length / 2] : (result[result.length / 2 - 1] + result[result.length / 2]) / 2.0;
    }
}
```

{% endnote %}

这道题可以转化为寻找两个（合并后的）有序数组中第k小的数，其中k为$\frac{m+n}{2}$或$\frac{m+n}{2}+1$。
假设两个有序数组分别为$\text{A}$和$\text{B}$，可以先比较$\text{A}[k/2-1]$和$\text{B}[k/2-1]$

- 若$\text{A}[k/2-1]<\text{B}[k/2-1]$，说明比$\text{A}[k/2-1]$小的数最多只有$\text{A}$的前$k/2-1$个数和$\text{B}$的前$k/2-1$个数，即最多$k-2$个，因此数$\text{A}[k/2-1]$不可能是第$k$个数，可以全部排除
- 若$\text{A}[k/2-1]>\text{B}[k/2-1]$，则排除$\text{B}[k/2-1]$
- 若$\text{A}[k/2-1]=\text{B}[k/2-1]$，则归入第一种情况处理
- 若$\text{A}[k/2-1]$或$\text{B}[k/2-1]$越界，取其最后一个元素。此时应该根据排除树的个数减少$k$的值而非$k/2$
- 若一个数组为空，我们直接返回另一个数组中第$k$小的元素
- 若$k=1$，只需要返回两个数组首元素的最小值即可

![图例](4_fig1.png)

```java
class Solution {
    public double findMedianSortedArrays(int[] nums1, int[] nums2) {
        int length1 = nums1.length, length2 = nums2.length;
        int totalLength = length1 + length2;
        if (totalLength % 2 == 1) {
            int midIndex = totalLength / 2;
            double median = getKthElement(nums1, nums2, midIndex + 1);
            return median;
        } else {
            int midIndex1 = totalLength / 2 - 1, midIndex2 = totalLength / 2;
            double median = (getKthElement(nums1, nums2, midIndex1 + 1) + getKthElement(nums1, nums2, midIndex2 + 1)) / 2.0;
            return median;
        }
    }

    public int getKthElement(int[] nums1, int[] nums2, int k) {
        int length1 = nums1.length, length2 = nums2.length;
        int index1 = 0, index2 = 0;
        int kthElement = 0;

        while (true) {
            if (index1 == length1) {
                return nums2[index2 + k - 1];
            }
            if (index2 == length2) {
                return nums1[index1 + k - 1];
            }
            if (k == 1) {
                return Math.min(nums1[index1], nums2[index2]);
            }
            
            int half = k / 2;
            int newIndex1 = Math.min(index1 + half, length1) - 1;
            int newIndex2 = Math.min(index2 + half, length2) - 1;
            int pivot1 = nums1[newIndex1], pivot2 = nums2[newIndex2];
            if (pivot1 <= pivot2) {
                k -= (newIndex1 - index1 + 1);
                index1 = newIndex1 + 1;
            } else {
                k -= (newIndex2 - index2 + 1);
                index2 = newIndex2 + 1;
            }
        }
    }
}
```

### 小巧思

#### 只出现一次的数字

给你一个 **非空** 整数数组 `nums` ，除了某个元素只出现一次以外，其余每个元素均出现两次。找出那个只出现了一次的元素。

{% note info %}
提示指明了方向。相同的数异或会变成0，只有唯一出现的数鹤立鸡群

```java
class Solution {
    public int singleNumber(int[] nums) {
        int ans = nums[0];
        for(int i = 1; i < nums.length; i++)
            ans ^= nums[i];
        return ans;
    }
}
```

{% endnote %}

脑筋急转弯了属于是。

#### 多数元素

给定一个大小为 `n` 的数组 `nums` ，返回其中的多数元素。多数元素是指在数组中出现次数 大于 `⌊ n/2 ⌋` 的元素。

##### Boyer-Moore 投票算法

遍历一遍，寻找候选元素

- 若票数为0，则将当前元素设为候选元素
- 相同元素加一票，相异元素减一票

再遍历一遍，验证候选元素是否确实超过了数组长度的一半。最后，如果确实超过了一半就返回该数。否则返回0（表示不存在）

```java
class Solution {
    public int majorityElement(int[] nums) {
        int x = 0, votes = 0, count = 0;
        for (int num : nums){
            if (votes == 0) x = num;
            votes += num == x ? 1 : -1;
        }
        for (int num : nums)
            if (num == x) count++;
        return count > nums.length / 2 ? x : 0;
    }
}
```

{% note success %}
但在此题中，题目已经说明了多数元素必然存在，因此验证这一步可以省略。但时间并不会有明显的变化。
{% endnote %}

##### 随机化

若找到了众数则返回，否则继续随机挑选

```java
class Solution {
    private int randRange(Random rand, int min, int max) {
        return rand.nextInt(max - min) + min;
    }

    private int countOccurences(int[] nums, int num) {
        int count = 0;
        for (int i = 0; i < nums.length; i++)
            if (nums[i] == num)
                count++;
        return count;
    }

    public int majorityElement(int[] nums) {
        Random rand = new Random();
        int majorityCount = nums.length / 2;
        while (true) {
            int candidate = nums[randRange(rand, 0, nums.length)];
            if (countOccurences(nums, candidate) > majorityCount)
                return candidate;
        }
    }
}
```

##### 排序

作为众数，无论有多大，取其中间位置一定正确。

#### 颜色分类

给定一个包含红色、白色和蓝色、共 `n` 个元素的数组 `nums` ，**原地** 对它们进行排序，使得相同颜色的元素相邻，并按照红色、白色、蓝色顺序排列。
我们使用整数 `0`、 `1` 和 `2` 分别表示红色、白色和蓝色。

{% note info %}
题目给的数组范围实在太小了，才300个，完全体现不出不同算法的差距。
可以不管题目要求，直接排序

```java
class Solution {
    public void sortColors(int[] nums) {
        Arrays.sort(nums);
    }
}
```

也可以按照提示的写法，先统计数量，然后再一个个覆盖数据

```java
class Solution {
    public void sortColors(int[] nums) {
        int zeros = 0, ones = 0, twos = 0, p = 0;
        for(int i : nums)
            switch(i) {
                case 0 -> zeros++;
                case 1 -> ones++;
                default -> twos++;
            };
        while(zeros-- != 0)
            nums[p++] = 0;
        while(ones-- != 0)
            nums[p++] = 1;
        while(twos-- != 0)
            nums[p++] = 2;
    }
}
```

但一个复杂度为$O(2n)$，一个复杂度为$O(n\log n)$，时间都是0ms，都没有差别了
{% endnote %}

官解的双指针能实现一次遍历即可得出结果。另外维护两个指针`p0`和`p1`，`i`在遍历时，找到0就和`num[p0]`替换，找到1就和`num[p1]`交换并让指针加1。

```java
class Solution {
    public void sortColors(int[] nums) {
        int n = nums.length, p0 = 0, p1 = 0, temp;
        for (int i = 0; i < n; ++i) {
            if (nums[i] == 1) {
                temp = nums[i];
                nums[i] = nums[p1];
                nums[p1] = temp;
                ++p1;
            } else if (nums[i] == 0) {
                temp = nums[i];
                nums[i] = nums[p0];
                nums[p0] = temp;
                if (p0 < p1) {
                    temp = nums[i];
                    nums[i] = nums[p1];
                    nums[p1] = temp;
                }
                ++p0;
                ++p1;
            }
        }
    }
}
```

#### 下一个排列

整数数组的一个 **排列**  就是将其所有成员以序列或线性顺序排列。

例如，`arr = [1,2,3]` ，以下这些都可以视作 arr 的排列：`[1,2,3]、[1,3,2]、[3,1,2]、[2,3,1]` 。
整数数组的 **下一个排列** 是指其整数的下一个字典序更大的排列。更正式地，如果数组的所有排列根据其字典顺序从小到大排列在一个容器中，那么数组的 **下一个排列** 就是在这个有序容器中排在它后面的那个排列。如果不存在下一个更大的排列，那么这个数组必须重排为字典序最小的排列（即，其元素按升序排列）。
给你一个整数数组 `nums` ，找出 `nums` 的下一个排列。
必须 **原地** 修改，只允许使用额外常数空间。

为了达到该要求

1. 我们需要将一个左边的“较小数”和右边的“较大数”替换
2. 同时我们让这个“较小数”尽量靠右，而“较大数”尽可能小。交换完成后。“较大数”右边的数需要按照身故重新排列。
3. 若步骤1找不到数，说明该序列已经是一个降序序列，则直接跳过步骤2来到步骤3

![示例](31.gif)

```java
class Solution {
    public void nextPermutation(int[] nums) {
        int i = nums.length - 2;
        while (i >= 0 && nums[i] >= nums[i + 1])
            i--;
        if (i >= 0) {
            int j = nums.length - 1;
            while (j >= 0 && nums[i] >= nums[j])
                j--;
            swap(nums, i, j);
        }
        reverse(nums, i + 1);
    }

    public void swap(int[] nums, int i, int j) {
        int temp = nums[i];
        nums[i] = nums[j];
        nums[j] = temp;
    }

    public void reverse(int[] nums, int start) {
        int left = start, right = nums.length - 1;
        while (left < right) {
            swap(nums, left, right);
            left++;
            right--;
        }
    }
}
```

#### 寻找重复数

给定一个包含 `n + 1` 个整数的数组 `nums` ，其数字都在 `[1, n]` 范围内，可知存在一个重复的整数。返回 **这个重复的数** 。
你设计的解决方案必须 **不修改** 数组 `nums` 且只用常量级 $O(1)$ 的额外空间。

{% note info %}
若不考虑空间复杂度，那么写出时间复杂度100%的代码是轻轻松松

```java
class Solution {
    public int findDuplicate(int[] nums) {
        boolean[] bitmap = new boolean[nums.length];
        int length = nums.length;
        for(int i = 0; i < length; ++i) {
            if(bitmap[nums[i]])
                return nums[i];
            else
                bitmap[nums[i]] = true;
        }
        return 0;
    }
}
```

{% endnote %}

##### 快慢指针

题目中指明了`1 <= nums[i] <= n`，那么可以用快慢指针了。让快指针走两步，慢指针走一步，[由此处的推导可以知道](https://ivanclf.github.io/2025/08/08/leetcode-2/#%E7%8E%AF%E5%BD%A2%E9%93%BE%E8%A1%A8II)，当快慢指针相遇时，让快指针从当前位置出发，慢指针从起点出发，最后相遇的地方就是重复数。

```java
class Solution {
    public int findDuplicate(int[] nums) {
        int slow = 0, fast = 0;
        do {
            slow = nums[slow];
            fast = nums[nums[fast]];
        } while (slow != fast);
        slow = 0;
        while (slow != fast) {
            slow = nums[slow];
            fast = nums[fast];
        }
        return slow;
    }
}
```

##### 二进制

维护`x`为数组中所有数字在第`bit`位为1的数量；维护`y`为理论上1到n-1这些数字在`bit`位的数量。若`x > y`，说明重复数字的这意味是1，则将结果的这一位置1。

```java
class Solution {
    public int findDuplicate(int[] nums) {
        int n = nums.length, ans = 0;
        int bit_max = 31;
        while (((n - 1) >> bit_max) == 0) {
            bit_max -= 1;
        }
        for (int bit = 0; bit <= bit_max; ++bit) {
            int x = 0, y = 0;
            for (int i = 0; i < n; ++i) {
                if ((nums[i] & (1 << bit)) != 0) {
                    x += 1;
                }
                if (i >= 1 && ((i & (1 << bit)) != 0)) {
                    y += 1;
                }
            }
            if (x > y) {
                ans |= 1 << bit;
            }
        }
        return ans;
    }
}
```

首先确定最大位数。然后逐位检查。对`x`则是拿现有的数字，对`y`则是理论上的数字（此处为索引`i`）。注意此处大循环的`bit`为第`i`位二进制数据，下一层循环为不同的数字。

##### 二分

统计小于等于`mid`的数字数量，若没有重复数字，那么对于任意数字`x`，数组中小于等于`x`的数字数量应该恰好等于`x`

```java
class Solution {
    public int findDuplicate(int[] nums) {
        int n = nums.length;
        int l = 1, r = n - 1, ans = -1;
        while (l <= r) {
            int mid = (l + r) >> 1;
            int cnt = 0;
            for (int i = 0; i < n; ++i) {
                if (nums[i] <= mid) {
                    cnt++;
                }
            }
            if (cnt <= mid) {
                l = mid + 1;
            } else {
                r = mid - 1;
                ans = mid;
            }
        }
        return ans;
    }
}
```

### 图论

#### 岛屿数量

给你一个由 `'1'`（陆地）和 `'0'`（水）组成的的二维网格，请你计算网格中岛屿的数量。岛屿总是被水包围，并且每座岛屿只能由水平方向和/或竖直方向上相邻的陆地连接形成。此外，你可以假设该网格的四条边均被水包围。

示例：
    输入：grid = [
    ["1","1","1","1","0"],
    ["1","1","0","1","0"],
    ["1","1","0","0","0"],
    ["0","0","0","0","0"]
    ]
    输出：1

{% note info %}
使用万能的dfs

```java
class Solution {
    char[][] grid;
    boolean[][] t;
    public int numIslands(char[][] grid) {
        if (grid.length == 1 && grid[0].length == 1)
            return grid[0][0] == '1' ? 1 : 0;
        this.grid = grid;
        t = new boolean[grid.length][grid[0].length];
        int ans = 0;
        for (int i = 0; i < grid.length; i++)
            for (int j = 0; j < grid[0].length; j++)
                if (grid[i][j] == '1' && !t[i][j]) {
                    ans++;
                    recursive(i, j);
                }
        return ans;
    }

    public void recursive(int i, int j) {
        t[i][j] = true;
        if (i - 1 > -1 && grid[i - 1][j] == '1' && !t[i - 1][j])
            recursive(i - 1, j);
        if (i + 1 < grid.length && grid[i + 1][j] == '1' && !t[i + 1][j])
            recursive(i + 1, j);
        if (j - 1 > -1 && grid[i][j - 1] == '1' && !t[i][j - 1])
            recursive(i, j - 1);
        if (j + 1 < grid[0].length && grid[i][j + 1] == '1' && !t[i][j + 1])
            recursive(i, j + 1);
    }
}
```

{% endnote %}

而官解直接让计算完的岛直接“淹掉”，节省了标记的空间

```java
class Solution {
    void dfs(char[][] grid, int r, int c) {
        int nr = grid.length;
        int nc = grid[0].length;

        if (r < 0 || c < 0 || r >= nr || c >= nc || grid[r][c] == '0') {
            return;
        }

        grid[r][c] = '0';
        dfs(grid, r - 1, c);
        dfs(grid, r + 1, c);
        dfs(grid, r, c - 1);
        dfs(grid, r, c + 1);
    }

    public int numIslands(char[][] grid) {
        if (grid == null || grid.length == 0) {
            return 0;
        }

        int nr = grid.length;
        int nc = grid[0].length;
        int num_islands = 0;
        for (int r = 0; r < nr; ++r) {
            for (int c = 0; c < nc; ++c) {
                if (grid[r][c] == '1') {
                    ++num_islands;
                    dfs(grid, r, c);
                }
            }
        }

        return num_islands;
    }
}
```

{% note primary %}

也可以使用bfs，其实就是用队列代替迭代了

```java
class Solution {
    public int numIslands(char[][] grid) {
        if (grid == null || grid.length == 0)
            return 0;

        int nr = grid.length;
        int nc = grid[0].length;
        int num_islands = 0;

        for (int r = 0; r < nr; ++r)
            for (int c = 0; c < nc; ++c)
                if (grid[r][c] == '1') {
                    ++num_islands;
                    grid[r][c] = '0';
                    Queue<Integer> neighbors = new LinkedList<>();
                    neighbors.add(r * nc + c);
                    while (!neighbors.isEmpty()) {
                        int id = neighbors.remove();
                        int row = id / nc;
                        int col = id % nc;
                        if (row - 1 >= 0 && grid[row-1][col] == '1') {
                            neighbors.add((row-1) * nc + col);
                            grid[row-1][col] = '0';
                        }
                        if (row + 1 < nr && grid[row+1][col] == '1') {
                            neighbors.add((row+1) * nc + col);
                            grid[row+1][col] = '0';
                        }
                        if (col - 1 >= 0 && grid[row][col-1] == '1') {
                            neighbors.add(row * nc + col-1);
                            grid[row][col-1] = '0';
                        }
                        if (col + 1 < nc && grid[row][col+1] == '1') {
                            neighbors.add(row * nc + col+1);
                            grid[row][col+1] = '0';
                        }
                    }
                }
        return num_islands;
    }
}
```

此处使用特殊算法，使得只用一个数存储两个变量（纵横坐标）成为可能。

{% endnote %}

或者可以使用并查集代替搜索。为了求出岛屿的数量，可以扫描整个二位网络。若一个位置是1，那么将其相邻4个方向上的1在并查集中进行合并。为此我们需要另外一个并查集对象。

```java
class Solution {
    class UnionFind {
        int count;
        int[] parent;
        int[] rank;

        public UnionFind(char[][] grid) {
            count = 0;
            int m = grid.length;
            int n = grid[0].length;
            parent = new int[m * n];
            rank = new int[m * n];
            for (int i = 0; i < m; ++i) {
                for (int j = 0; j < n; ++j) {
                    if (grid[i][j] == '1') {
                        parent[i * n + j] = i * n + j;
                        ++count;
                    }
                    rank[i * n + j] = 0;
                }
            }
        }

        public int find(int i) {
            if (parent[i] != i)
                parent[i] = find(parent[i]);
            return parent[i];
        }

        public void union(int x, int y) {
            int rootx = find(x);
            int rooty = find(y);
            if (rootx != rooty) {
                if (rank[rootx] > rank[rooty])
                    parent[rooty] = rootx;
                else if (rank[rootx] < rank[rooty])
                    parent[rootx] = rooty;
                else {
                    parent[rooty] = rootx;
                    rank[rootx] += 1;
                }
                --count;
            }
        }

        public int getCount() {
            return count;
        }
    }

    public int numIslands(char[][] grid) {
        if (grid == null || grid.length == 0)
            return 0;

        int nr = grid.length;
        int nc = grid[0].length;
        int num_islands = 0;
        UnionFind uf = new UnionFind(grid);
        for (int r = 0; r < nr; ++r)
            for (int c = 0; c < nc; ++c)
                if (grid[r][c] == '1') {
                    grid[r][c] = '0';
                    if (r - 1 >= 0 && grid[r-1][c] == '1')
                        uf.union(r * nc + c, (r-1) * nc + c);
                    if (r + 1 < nr && grid[r+1][c] == '1')
                        uf.union(r * nc + c, (r+1) * nc + c);
                    if (c - 1 >= 0 && grid[r][c-1] == '1')
                        uf.union(r * nc + c, r * nc + c - 1);
                    if (c + 1 < nc && grid[r][c+1] == '1')
                        uf.union(r * nc + c, r * nc + c + 1);
                }

        return uf.getCount();
    }
}
```

#### 腐烂的橘子

在给定的 `m x n` 网格 `grid` 中，每个单元格可以有以下三个值之一：

- 值 `0` 代表空单元格；
- 值 `1` 代表新鲜橘子；
- 值 `2` 代表腐烂的橘子。

每分钟，腐烂的橘子 周围 `4` 个方向上相邻 的新鲜橘子都会腐烂。
返回 *直到单元格中没有新鲜橘子为止所必须经过的最小分钟数*。如果不可能，返回 `-1` 。

{% note info %}
官解在叽里咕噜干嘛呢？
其实最简单的办法就是多次循环。第一次找出腐烂的橘子，第二次开始bfs，第三次开始查看是否还有没腐烂的橘子。足矣

```java
class Solution {
    public int orangesRotting(int[][] grid) {
        int m = grid.length, n = grid[0].length, ans = 0;
        Queue<Integer> queue = new LinkedList<>();
        for(int i = 0; i < m; i++)
            for(int j = 0; j < n; j++)
                if(grid[i][j] == 2)
                    queue.add(i * n + j);
        while(!queue.isEmpty()) {
            int size = queue.size();
            for (int i = 0; i < size; i++) {
                int rot = queue.remove(), row = rot / n, col = rot % n;
                grid[row][col] = 2;
                if (row - 1 >= 0 && grid[row - 1][col] == 1) {
                    queue.add((row - 1) * n + col);
                    grid[row - 1][col] = 2;
                }
                if (row + 1 < m && grid[row + 1][col] == 1) {
                    queue.add((row + 1) * n + col);
                    grid[row + 1][col] = 2;
                }
                if (col - 1 >= 0 && grid[row][col - 1] == 1) {
                    queue.add(row * n + col - 1);
                    grid[row][col - 1] = 2;
                }
                if (col + 1 < n && grid[row][col + 1] == 1) {
                    queue.add(row * n + col + 1);
                    grid[row][col + 1] = 2;
                }
            }
            if(!queue.isEmpty())
                ans++;
        }
        for(int i = 0; i < m; i++)
            for(int j = 0; j < n; j++)
                if(grid[i][j] == 1)
                    return -1;
        return ans;
    }

}
```

为什么不能使用dfs呢？因为初始腐烂的橘子不止一个，需要在某一步将所有可能的腐烂的情况都考虑进去，这种情况下拿dfs就不太好解决了。
{% endnote %}

以下是官解的写法

```java
class Solution {
    int[] dr = new int[]{-1, 0, 1, 0};
    int[] dc = new int[]{0, -1, 0, 1};

    public int orangesRotting(int[][] grid) {
        int R = grid.length, C = grid[0].length;
        Queue<Integer> queue = new ArrayDeque<Integer>();
        Map<Integer, Integer> depth = new HashMap<Integer, Integer>();
        for (int r = 0; r < R; ++r) {
            for (int c = 0; c < C; ++c) {
                if (grid[r][c] == 2) {
                    int code = r * C + c;
                    queue.add(code);
                    depth.put(code, 0);
                }
            }
        }
        int ans = 0;
        while (!queue.isEmpty()) {
            int code = queue.remove();
            int r = code / C, c = code % C;
            for (int k = 0; k < 4; ++k) {
                int nr = r + dr[k];
                int nc = c + dc[k];
                if (0 <= nr && nr < R && 0 <= nc && nc < C && grid[nr][nc] == 1) {
                    grid[nr][nc] = 2;
                    int ncode = nr * C + nc;
                    queue.add(ncode);
                    depth.put(ncode, depth.get(code) + 1);
                    ans = depth.get(ncode);
                }
            }
        }
        for (int[] row: grid) {
            for (int v: row) {
                if (v == 1) {
                    return -1;
                }
            }
        }
        return ans;
    }
}
```

#### 课程表

你这个学期必须选修 `numCourses` 门课程，记为 0 到 `numCourses - 1` 。
在选修某些课程之前需要一些先修课程。 先修课程按数组 prerequisites 给出，其中 `prerequisites[i] =[ai, bi]` ，表示如果要学习课程 `ai` 则 必须 先学习课程  `bi` 。
例如，先修课程对 `[0, 1]` 表示：想要学习课程 `0` ，你需要先完成课程 `1` 。
请你判断是否可能完成所有课程的学习？如果可以，返回 `true` ；否则，返回 `false` 。

给定一格包含$n$个节点的有向图$G$，若$G$中的任一条有向边$(u,v)$，$u$的排列中都出现在$v$的前面，那么称该排列是图$G$的**拓补排序**。由该定义我们可以得出两个结论

- 若$G$存在环，那么$G$不存在拓补排序
- 若$G$是有序无环图，那么其拓补排序可能不止一种

##### dfs

假设我们当前搜索到了节点$u$，如果它的所有相邻节点都已经搜索完成，那么这些节点都已经在栈中了，此时我们就可以把$u$入栈。这样，我们对图进行一遍dfs。当每个节点进行回溯的时候，我们把该节点放入栈中，最终从栈顶到栈底的序列就是一种拓补排序。

对图中任意一个节点，它在搜索过程中有三种状态，即：

- 未搜索
- 搜索中，此时正在等待回溯
- 已完成，已经入栈，再遍历就跳过

我们任取一个未搜索的节点开始dfs，将当前节点$u$标记为“搜索中”，遍历该节点的每一个相邻节点$v$

- 若$v$为“未搜索”，就搜索$v$
- 若$v$为搜索中，那么就找到了环
- 若$v$为已完成，那么就不用进行任何操作，因为此时无论何时入栈都不影响$(u,v)$的拓补关系

当$u$是所有节点都为“未完成”时，我们将$u$放入栈中，并将其标记为“已完成”

```java
class Solution {
    List<List<Integer>> edges;
    int[] visited;
    boolean valid = true;

    public boolean canFinish(int numCourses, int[][] prerequisites) {
        edges = new ArrayList<List<Integer>>();
        for (int i = 0; i < numCourses; ++i) {
            edges.add(new ArrayList<Integer>());
        }
        visited = new int[numCourses];
        for (int[] info : prerequisites) {
            edges.get(info[1]).add(info[0]);
        }
        for (int i = 0; i < numCourses && valid; ++i)
            if (visited[i] == 0)
                dfs(i);
        return valid;
    }

    public void dfs(int u) {
        visited[u] = 1;
        for (int v: edges.get(u)) {
            if (visited[v] == 0) {
                dfs(v);
                if (!valid)
                    return;
            } else if (visited[v] == 1) {
                valid = false;
                return;
            }
        }
        visited[u] = 2;
    }
}
```

##### bfs

取出队首节点$u$，将其放入答案中，并移除其所有出边，也就是将$u$的所有相邻节点的入度减少1.若某个相邻节点$v$的入度变为0，那么就将$v$放入队列中
若答案中包含了这$n$个节点，那么我们就找到了一种拓补排序。由于只是判断是否存在拓补排序，因此不需要存放答案数组，只需要用一个变量记录被放入的元素数量就行

```java
class Solution {
    List<List<Integer>> edges;
    int[] indeg;

    public boolean canFinish(int numCourses, int[][] prerequisites) {
        edges = new ArrayList<List<Integer>>();
        for (int i = 0; i < numCourses; ++i)
            edges.add(new ArrayList<Integer>());
        indeg = new int[numCourses];
        for (int[] info : prerequisites) {
            edges.get(info[1]).add(info[0]);
            ++indeg[info[0]];
        }

        Queue<Integer> queue = new LinkedList<Integer>();
        for (int i = 0; i < numCourses; ++i)
            if (indeg[i] == 0)
                queue.offer(i);

        int visited = 0;
        while (!queue.isEmpty()) {
            ++visited;
            int u = queue.poll();
            for (int v: edges.get(u)) {
                --indeg[v];
                if (indeg[v] == 0)
                    queue.offer(v);
            }
        }

        return visited == numCourses;
    }
}
```

#### 实现Trie(前缀树)

Trie或者说 **前缀树** 是一种树形数据结构，用于高效地存储和检索字符串数据集中的键。这一数据结构有相当多的应用情景，例如自动补全和拼写检查。

请你实现 `Trie` 类：

- `Trie()` 初始化前缀树对象。
- `void insert(String word)` 向前缀树中插入字符串 `word` 。
- `boolean search(String word)` 如果字符串 `word` 在前缀树中，返回 `true`（即，在检索之前已经插入）；否则，返回 `false` 。
- `boolean startsWith(String prefix)` 如果之前已经插入的字符串 `word` 的前缀之一为 `prefix` ，返回 `true` ；否则，返回 `false` 。

没什么思维上的难度，主要是细节方面，直接上源码吧

```java
class Trie {
    private Trie[] children;
    private boolean isEnd;

    public Trie() {
        children = new Trie[26];
        isEnd = false;
    }
    
    public void insert(String word) {
        Trie node = this;
        for (int i = 0; i < word.length(); i++) {
            char ch = word.charAt(i);
            int index = ch - 'a';
            if (node.children[index] == null) {
                node.children[index] = new Trie();
            }
            node = node.children[index];
        }
        node.isEnd = true;
    }
    
    public boolean search(String word) {
        Trie node = searchPrefix(word);
        return node != null && node.isEnd;
    }
    
    public boolean startsWith(String prefix) {
        return searchPrefix(prefix) != null;
    }

    private Trie searchPrefix(String prefix) {
        Trie node = this;
        for (int i = 0; i < prefix.length(); i++) {
            char ch = prefix.charAt(i);
            int index = ch - 'a';
            if (node.children[index] == null) {
                return null;
            }
            node = node.children[index];
        }
        return node;
    }
}
```