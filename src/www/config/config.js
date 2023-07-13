const HomerConfig = new (class {

    objFillForm(obj, form, preserve = false) {
        form.querySelectorAll('input[name], select[name], textarea[name]').forEach(input => {
            const name = input.name;
            if (obj.hasOwnProperty(name) || !preserve) {
                input.value = obj[name];
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

})();
