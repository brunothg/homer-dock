// Copyright 2023 brunothg
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//       http://www.apache.org/licenses/LICENSE-2.0
const HomerLang = new (class {
    thisScript;
    constructor() {
        this.thisScript = document.currentScript;
    }

    getLang(simple = true) {
        let lang = navigator.language;
        return (simple) ? lang.substring(0, (lang.indexOf('-') >= 0) ? lang.indexOf('-') : lang.length) : lang;
    }

    async getLangValues(lang = undefined, defaultLang = null) {
        if (!lang) {
            lang = this.getLang();
        }

        let respLang = await fetch(`${this.thisScript.src}/../values/${lang}.json`);
        if (!respLang.ok) {
            console.warn("Could not load language: ", lang)
            lang = null;
            if (defaultLang) {
                lang = defaultLang;
                respLang = await fetch(`./${lang}.json`);
            }
        }
        return ({lang: lang, values: (respLang.ok) ? await respLang.json() : {}});
    }

    async getLangValue(key, lang = undefined, defaultLang = null) {
        const langResp = await this.getLangValues(lang, defaultLang);
        return (langResp) ? langResp.values[key] : undefined;
    }

    async updatePageLang(lang = undefined, defaultLang = null) {
        const langResp = await this.getLangValues(lang, defaultLang);

        if (langResp) {
            lang = langResp?.lang
            const langVal = langResp?.values;

            document.documentElement.setAttribute("lang", lang);
            document.querySelectorAll('*[data-lang]').forEach(ele => {
                const langKey = ele.dataset.lang;
                const langValue = langVal[langKey];
                console.debug("Update lang ", ele, `${langKey} -> ${langValue}`);

                if (langValue) {
                    ele.innerText = langValue;
                }
            })
        }

        return lang
    }

})();

document.addEventListener("DOMContentLoaded", () => {
    HomerLang.updatePageLang().then((effectiveLang) => {
        console.log("Updated page language: ", effectiveLang);
    })
});
