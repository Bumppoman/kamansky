const colors = require('tailwindcss/colors');
const defaultTheme = require('tailwindcss/defaultTheme');

module.exports = {
  mode: 'jit',
  purge: ['./ts/**/*.ts', './node_modules/phoenix*/**/*.js', '../lib/*_web/**/*.*ex'],
  theme: {
    extend: {
      colors: {
        'warm-gray': colors.warmGray
      },
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
      scale: {
        '10': '0.1'
      }
    },
  },
  variants: {
    extend: {},
  },
  plugins: [
    require('@tailwindcss/forms')
  ],
};