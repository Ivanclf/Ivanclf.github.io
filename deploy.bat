@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ===== 配置区域 =====
set SOURCE_BRANCH=hexo-source
set DEPLOY_BRANCH=main
set REPO_URL=https://github.com/Ivanclf/Ivanclf.github.io.git
:: ====================

:: 第一步：检查并提交源码分支
git add . >nul 2>&1

set has_changes=0
git diff-index --quiet HEAD -- || set has_changes=1

if !has_changes! equ 1 (
    git commit -m "Update source: %date% %time%" >nul
    git push origin %SOURCE_BRANCH% >nul
    echo Source branch updated: %SOURCE_BRANCH%
) else (
    echo Source branch no changes
)

:: 第二步：部署静态文件分支
set DEPLOY_DIR=.deploy_temp
if exist "%DEPLOY_DIR%" rd /s /q "%DEPLOY_DIR%" >nul 2>&1
mkdir "%DEPLOY_DIR%" >nul 2>&1

git clone -b %DEPLOY_BRANCH% %REPO_URL% "%DEPLOY_DIR%" --depth 1 >nul 2>&1

cd "%DEPLOY_DIR%"
for /f "delims=" %%i in ('dir /b /a ^| findstr /v /i ".git"') do (
    attrib -r -a -s -h "%%i" >nul 2>&1
    rd /s /q "%%i" 2>nul || del /f /q "%%i" 2>nul
)

xcopy /s /e /y "..\public\*" "." >nul

set static_changes=0
git diff-index --quiet HEAD -- || set static_changes=1

if !static_changes! equ 1 (
    git add . >nul
    git commit -m "Update static files: %date% %time%" >nul
    git push origin %DEPLOY_BRANCH% >nul
    echo Static branch updated: %DEPLOY_BRANCH%
) else (
    echo Static branch no changes
)

cd ..
rd /s /q "%DEPLOY_DIR%" >nul 2>&1