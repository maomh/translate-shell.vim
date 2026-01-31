" =================== Vim翻译插件 - trans命令版 =====================
" 功能：
"   1.光标停在单词上，按快捷键翻译单个单词
"   2.可视化模式选中单词/句子/段落，按快捷键翻译选中内容
" ===================================================================
function! TranslateSelectedText(mode = '') abort
    " 1. 获取选中的内容 / 光标所在单词
    let s:selected_text = ''
    if a:mode == 'v' || a:mode == 'V'
        " 可视化模式下获取选中内容
        let s:old_reg = getreg('"')
        normal! gvy
        let s:selected_text = trim(getreg('"'))
        call setreg('"', s:old_reg)
    elseif a:mode == "\<C-V>"
        " 可视化块模式下获取选中内容
        echoerr "❌ 很抱歉，块选择模式暂不支持翻译！"
        return
    else
        " 普通模式：获取光标所在的单词（光标在单词任意位置都可以）
        let s:selected_text = trim(expand('<cword>'))
    endif

    if empty(s:selected_text)
        echoerr "❌ 请选中单词/句子，或把光标放在单词上！"
        return
    endif

    " echo "🌐 翻译中，请稍候..."

    if !exists('g:translate_shell_from_to')
        let g:translate_shell_from_to = 'en:zh' " 默认翻译方向：英文→中文
    endif

    " 2. 核心：调用系统trans命令，翻译方向【自动识别→中文】，获取翻译结果
    " en:zh 强制英文译中文，zh:en 强制中文译英文，auto:zh 自动识别源语言译中文
    let s:cmd = 'trans -no-ansi ' 
                \. trim(g:translate_shell_from_to) 
                \. ' "' . s:selected_text . '"'
    let s:result = system(s:cmd)

    " 3. 处理翻译结果展示
    if v:shell_error != 0
        echoerr "❌ 翻译失败：请检查trans命令是否可用"
    elseif empty(s:result)
        echoerr "❌ 无翻译结果：请确认输入内容"
    else
        if v:version < 802
            " 底部回显翻译结果（简洁）
            echo "✅ " . s:selected_text . " → " . s:result
        else
            " 新建一个预览窗口展示完整翻译
            let lines = split(s:result, '\n')
            call popup_create(lines, {
                        \'title': '【翻译结果】', 
                        \'line': 'cursor+1',
                        \'col': 'cursor',
                        \'border': [1],
                        \'padding': [0,1,0,1],
                        \'moved': 'word',
                        \})
        endif
    endif
endfunction

" ===================== 配置快捷键 =====================
" 推荐配置：普通模式+可视化模式 按 <leader>t 触发翻译
nnoremap <silent> <leader>t :call TranslateSelectedText()<CR>
vnoremap <silent> <leader>t :<C-U>call TranslateSelectedText(visualmode())<CR>
