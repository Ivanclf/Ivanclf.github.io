---
title: git的常见用法
date: 2024-05-15 20:49:41
tags: [碎片知识]
---

## 暂存区

暂存区暂时存储相关文件
- `git add .` 将所有文件放入暂存区，若不需要所有文件放入就将 `.` 改为文件名
- `git add --all` 将工作区中的所有变化都添加到暂存区，包括删除
- `git restore --staged <file>` 将指定文件从暂存区撤回到工作区，但本地的文件不会改变
- `git reset HEAD <file>` 和上个同理
- `git restore <file>` 将指定文件还原到暂存区的状态
- `git checkout -- <file>` 和上个同理
- `git status` 查看暂存区状态
- `git diff --staged` `git diff --cached` 比较暂存区和本地库中最新提交的差异

## 本地库

本地库保存了项目的所有提交历史
- `git commit` 提交暂存区的文件，需要写提交说明
- `git commit -a` 提交前会自动执行一步 `git add -u`，即添加所有已跟踪文件的修改和删除
- `git commit --amend` 修改最近一次提交的说明信息，或者将当前暂存区的更改追加到上一次提交中
- `git log` 查看详细的提交历史
    - `--oneline` 以单行模式查看
    - `--graph` 以拓补图的形式查看
    - `show <commit-id>` 查看某一次提交的详细信息
- `git reset` 回退到指定提交
    - `--soft <commit-id>` 保留更改作为已暂存状态，工作区保存更改
    - `--mixed <commit-id>` 默认模式，暂存区重置，工作区保留更改
    - `--hard <commit-id>` 丢弃所有更改

## 远程库

远程库一般在 GitHub、gitee 等网站上
- `git clone` 克隆项目到当前目录
- `git remote add origin <url>` 为远程库添加一个名字为 origin 的别名
- `git remote -v` 查看已配置的远程库别名和对应的 url
- `git remote show origin` 查看远程库 origin 的详细信息
- `git fetch origin` 从远程库下载所有最新的链接，但还不会合并到当前的工作分支，也不会修改工作区
- `git pull` 相当于 `git fetch` + `git merge` 下载数据并进行合并
- `git pull --rebase` 相当于 `gti fetch` + `git rebase`，使提交历史更加简洁，避免不必要的合并提交
- `git push` 向远程库提交代码
- `git push -u` 提交的同时建立上游关联，这样下次只需要打 `git push` 就可以了，不需要指定名字
- `git push --force-with-lease` 强制提交。只有在自己的本地远程跟踪分支是最新的情况下才能覆盖
- `git push -f` 强制提交

## 分支

- `git branch` 列出所有本地分支
    - `-v` 查看本地分支和其最新提交信息
    - `-vv` 查看本地分支及其跟踪的远程分支关系
    - `-r` 列出所有远程跟踪分支
    - `-a` 列出所有本地和远程分支
    - `<branch name>` 基于当前提交创建新分支
    - `<branch name> <commit-id>` 基于特定提交创建新分支
    - `<branch name> <tag name>` 基于标签创建新分支
    - `--merged` 查看已合并到当前分支的分支列表
    - `--no-merged` 查看未合并到当前分支的分支列表
    - `--merged | grep -v "\*" | xargs git branch -d` 批量删除已合并分支，但保留当前分支
    - `-m` 重命名当前分支
- `git checkout` 创建或切换分支
    - `<branch name>` 切换到新分支
    - `-b <branch name>` 创建并切换到新分支
    - `-` 切换到上一分支
    - `-d <branch name>` 安全删除，只在分支已合并时允许
    - `-D <branch name>` 强制删除
- `git merge` 将指定分支合并到当前分支
    - `--no-diff` 禁用快进合并，总是创建合并提交
    - `--squash` 将多个提交压缩成一个，然后提交
    - `--continue` 解决冲突后继续合并
    - `--abort` 中止合并，回到合并前的状态
- `git rebase` 将当前分支变基到指定分支
    - `--interactive <commit-id>` 交互式变基，可以编辑、合并、重排提交
    - `--abort` 中止变基操作
    - `--continue` 解决冲突后继续变基
- `git push origin --delete <branch name>` 删除远程分支
- `git diff <branch name 1>..<branch name 2>` 比较两个分支的差异
- `git diff <branch name 1>...<branch name 2>` 比较两个分支从共同祖先开始的差异
- `git log <branch name 1>..<branch name 2>` 查看分支2有但分支1没有的提交
- `gti log --oneline --graph --all` 图形化显示所有分支历史

{% note info %}
要修改历史中的某次提交（比如倒数第三次提交）中的 README 文件

```bash
# 启动交互式变基，编辑最近3次提交
git rebase -i HEAD~3

# 在编辑器中找到要修改的那次提交，将前面的 pick 改为 edit，保存退出

# 现在 git 停在了那次上，可以修改工作区中的文件了

# 修改完后，正常操作
git add <file>
git commit -amend
git rebase --continue
```

{% endnote %}