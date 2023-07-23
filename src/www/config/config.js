const HomerConfig = new (class {

            objFillForm(obj, form, preserve = false) {
                form.querySelectorAll('input[name], select[name], textarea[name]').forEach(input => {
                    const name = input.name;
                    if (obj.hasOwnProperty(name) || !preserve) {
                        input.value = obj[name] || null;
                        input.dispatchEvent(new Event('change'));
                    }
                })
            }

            formToObj(form) {
                if (!form) {
                    return null;
                }
                const formData = new FormData(form);

                const dataObj = {};
                for (const key of formData.keys()) {
                    const values = formData.getAll(key);
                    dataObj[key] = (values == null || values.length <= 0) ? null : (values.length === 1) ? values[0] : values;
                }

                return dataObj;
            }

            color2Rgba(color) {
                let r = 0,
                    g = 0,
                    b = 0,
                    a = 1.0;

                if (color) {
                    if (typeof color === 'string') {
                        if (color.startsWith('rgb')) {
                            const parts = color
                                .split(new RegExp('[(),]'))
                                .filter(ele => ele != null && !Number.isNaN(parseFloat(ele)));
                            r = (parts.length > 0) ? parseInt(parts[0]) : 0;
                            g = (parts.length > 1) ? parseInt(parts[1]) : 0;
                            b = (parts.length > 2) ? parseInt(parts[2]) : 0;
                            a = (parts.length > 3) ? parseFloat(parts[3]) : 1.0;
                        } else if (color.startsWith('#')) {
                            const parts = (color
                                .substring(1)
                                .match(new RegExp('.{1,2}', 'g')) || [])
                                .filter(ele => ele != null && !Number.isNaN(parseInt(ele, 16)));
                            r = (parts.length > 0) ? parseInt(parts[0], 16) : 0;
                            g = (parts.length > 1) ? parseInt(parts[1], 16) : 0;
                            b = (parts.length > 2) ? parseInt(parts[2], 16) : 0;
                            a = (parts.length > 3) ? (parseInt(parts[3], 16) / 255.0) : 1.0;
                        }
                    }
                } else if (typeof color === 'object') {
                    if (
                        ['r', 'g', 'b']
                            .map(ele => color.hasOwnProperty(ele))
                            .reduce((acc, cur) => acc && cur)
                    ) {
                        r = color.r || 0;
                        g = color.g || 0;
                        b = color.b || 0;
                        a = (color.a != null) ? color.a : 1.0;
                    }
                }

                return ({r: r, g: g, b: b, a: a})
            }

            color2Hsla(color) {
                const rgba = this.color2Rgba(color);

                const r = rgba.r / 255;
                const g = rgba.g / 255;
                const b = rgba.b / 255;
                const a = rgba.a;

                const cmin = Math.min(r, g, b);
                const cmax = Math.max(r, g, b);
                const delta = cmax - cmin;

                let h, s, l;

                if (delta === 0) {
                    h = 0;
                } else if (cmax === r) {
                    h = ((g - b) / delta) % 6;
                } else if (cmax === g) {
                    h = (b - r) / delta + 2;
                } else {
                    h = (r - g) / delta + 4;
                }

                h = Math.round(h * 60);
                if (h < 0) {
                    h += 360;
                }

                l = (cmax + cmin) / 2;
                s = delta === 0 ? 0 : delta / (1 - Math.abs(2 * l - 1));
                s = +(s * 100).toFixed(1);
                l = +(l * 100).toFixed(1);

                return ({h: h, s: s, l: l, a: a});
            }

            async updateTheme() {
                const manifestResp = await fetch('config/manifest/manifest.exec');
                if (!manifestResp.ok) {
                    console.warn("Could not load manifest:", manifestResp.status, manifestResp.statusText);
                    return;
                }
                const manifest = await manifestResp.json();
                const themeColor = '' + manifest['theme_color'];

                if (themeColor) {
                    const hsla = this.color2Hsla(themeColor);
                    console.log("Update theme color", themeColor, hsla)

                    const docStyle = document.querySelector(':root').style;
                    docStyle.setProperty('--w3-theme-hsl-h', hsla.h)
                    docStyle.setProperty('--w3-theme-hsl-s', hsla.s + '%')
                    docStyle.setProperty('--w3-theme-hsl-l', hsla.l + '%')
                }
            }

        }

    )()
;

document.addEventListener(
    "DOMContentLoaded"
    , () => {
        HomerConfig
            .updateTheme()
            .then();
    }
);
