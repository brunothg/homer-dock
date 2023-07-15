// Copyright 2023 brunothg
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//       http://www.apache.org/licenses/LICENSE-2.0
const PrismEditor = new (class {

    #editors = [];

    #escapeHTML = str =>
        str.replace(
            /[&<>'"]/g,
            tag =>
                ({
                    '&': '&amp;',
                    '<': '&lt;',
                    '>': '&gt;',
                    "'": '&#39;',
                    '"': '&quot;'
                }[tag] || tag)
        );

    register(ele) {
        const editor = ele.querySelector('textarea');
        const highlighter = document.createElement('pre');
        const highlighterContent = document.createElement('code');

        ele.innerHTML='';
        highlighter.appendChild(highlighterContent);
        ele.appendChild(editor);
        ele.appendChild(highlighter);

        const language = ele.dataset.prismLang;
        if (!editor || !highlighterContent || !language) {
            console.warn("Missing editor, highlighter or language for: ", ele);
        }
        console.log("Register ele editor for: ", ele);
        editor.setAttribute('spellcheck', 'false');
        highlighterContent.classList.add(`language-${language}`);
        highlighterContent.setAttribute('aria-hidden', 'true');

        const syncScroll = () => {
            highlighter.scrollTop = editor.scrollTop;
            highlighter.scrollLeft = editor.scrollLeft;
        };
        const update = () => {
            let text = '' + editor.value;
            if (text.endsWith("\n")) {
                text += " ";
            }
            highlighterContent.innerHTML = this.#escapeHTML(text);
            Prism.highlightElement(highlighterContent);
            syncScroll();
        };
        const inputListener = () => {
            update();
        };
        editor.addEventListener('input', inputListener);
        const changeListener = () => {
            update();
        };
        editor.addEventListener('change', changeListener);
        const scrollListener = () => {
            syncScroll();
        };
        editor.addEventListener('scroll', scrollListener);
        const keyListener = (ev) => {
            let text = '' + editor.value;
            if (ev.key === 'Tab') {
                ev.preventDefault();

                let before_tab = text.slice(0, editor.selectionStart);
                let after_tab = text.slice(editor.selectionEnd, editor.value.length);
                let cursor_pos = editor.selectionEnd + 1;
                text = before_tab + "\t" + after_tab;

                editor.value = text;
                editor.selectionStart = cursor_pos;
                editor.selectionEnd = cursor_pos;
                editor.dispatchEvent(new Event('change'));
            }
        };
        editor.addEventListener('keydown', keyListener);

        this.#editors.push({
            ele,
            editor,
            highlighter: highlighterContent,
            language,
            listeners: {input: inputListener, scroll: scrollListener, keydown: keyListener, change: changeListener}
        });
    }

    unregister(ele) {
        console.log("Register ele editor for: ", ele);
        const editor = this.#editors.find(editor => editor.ele === ele);
        if (editor) {
            for (const type in editor.listeners) {
                const listener = editor.listeners[type];
                editor.ele.removeEventListener(type, listener);
            }
        }
        this.#editors = this.#editors.filter(editor => editor.ele !== ele);
    }

    highlightAll() {
        const currentEditors = [].concat(this.#editors);
        currentEditors.forEach(ele => this.unregister(ele));

        const prismEditors = document.querySelectorAll('.prism-editor');
        prismEditors.forEach(ele => this.register(ele));
    }

})();
