const colors = require('tailwindcss/colors');
const defaultTheme = require('tailwindcss/defaultTheme');

module.exports = {
  mode: 'jit',
  content: ['./ts/**/*.ts', './node_modules/phoenix*/**/*.js', '../lib/*_web/**/*.*ex'],
  theme: {
    extend: {
      colors: {
        green: colors.emerald
      },
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
      scale: {
        '10': '0.1'
      }
    },
  },
  plugins: [
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/forms')
  ],
};