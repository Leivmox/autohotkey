; ==================================================================
; 【MSYS2 快捷方式一键生成器】
; ==================================================================

; ⚠️ 在这里修改你的配置
MSYS2_BIN_DIR := "D:\Windows\msys2\home\[用户名]\bin"

#z:: {
    global MSYS2_BIN_DIR

    ; 1. 清空剪贴板并发送 Ctrl+C 获取文件路径
    A_Clipboard := ""
    Send("^c")
    if !ClipWait(1) {
        ShowTip("❌ 未获取到文件路径，请确保选中了文件！")
        return
    }

    winPath := A_Clipboard

    ; 防止多选
    if InStr(winPath, "`n") {
        ShowTip("❌ 请每次只选中单个文件！")
        return
    }

    ; 2. 如果是 .lnk，解析出真实目标路径（Windows 会自动解析到最终目标）
    SplitPath(winPath, , , &ext)
    if (ext = "lnk") {
        shell := ComObject("WScript.Shell")
        sc := shell.CreateShortcut(winPath)
        resolved := sc.TargetPath
        if (resolved = "") {
            ShowTip("❌ 无法解析快捷方式目标路径！")
            return
        }
        winPath := resolved
        SplitPath(winPath, , , &ext)
    }

    ; 3. 限制只处理 .exe 文件（.lnk 解析后也必须指向 exe）
    if (ext != "exe") {
        ShowTip("❌ 仅支持 .exe 和 .lnk（指向 exe）文件！`n当前文件类型: ." ext)
        return
    }

    ; 4. 解析文件名作为默认命令名（去掉后缀）
    SplitPath(winPath, , , , &nameNoExt)

    ; 5. 弹出输入框确认命令名
    IB := InputBox("请输入你想在 MSYS2 中使用的命令名:`n(指向: " winPath ")", "创建终端快捷方式", "w400 h130", nameNoExt)
    if IB.Result = "Cancel"
        return

    cmdName := IB.Value
    if (cmdName = "")
        return

    ; 6. 确保 bin 目录存在
    if !DirExist(MSYS2_BIN_DIR)
        DirCreate(MSYS2_BIN_DIR)

    scriptPath := MSYS2_BIN_DIR "\" cmdName

    ; 7. 生成脚本内容（LF 换行，UTF-8 无 BOM）
    scriptContent := "#!/bin/zsh`n"
    scriptContent .= "# 由 AHK 自动生成于 " A_YYYY "-" A_MM "-" A_DD " " A_Hour ":" A_Min ":" A_Sec "`n"
    scriptContent .= 'start "" "' winPath '" "$@"' "`n"

    ; 8. 写入文件
    if FileExist(scriptPath)
        FileDelete(scriptPath)
    FileAppend(scriptContent, scriptPath, "UTF-8-RAW")

    ShowTip("✅ 成功创建命令: " cmdName "`n→ " winPath)
}

; ==================================================================
; 工具函数
; ==================================================================
ShowTip(msg, duration := 2500) {
    TrayTip(msg, "MSYS2 快捷方式生成器", "Iconi")
    SetTimer(() => TrayTip(), -duration)
}
