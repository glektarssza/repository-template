export default {
    arrowParens: 'always',
    bracketSameLine: true,
    bracketSpacing: false,
    endOfLine: 'lf',
    embeddedLanguageFormatting: 'auto',
    experimentalOperatorPosition: 'end',
    experimentalTernaries: true,
    htmlWhitespaceSensitivity: 'css',
    jsxSingleQuote: false,
    objectWrap: 'preserve',
    overrides: [
        {
            files: ['*.{yml,yaml}'],
            options: {
                tabWidth: 2
            }
        },
        {
            files: ['.github/workflows/**/*.{yml,yaml}'],
            options: {
                printWidth: 120,
                tabWidth: 2
            }
        }
    ],
    printWidth: 80,
    proseWrap: 'always',
    quoteProps: 'as-needed',
    singleAttributePerLine: false,
    singleQuote: true,
    semi: true,
    tabWidth: 4,
    trailingComma: 'none',
    vueIndentScriptAndStyle: true,
    useTabs: false
};
