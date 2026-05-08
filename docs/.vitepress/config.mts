import { defineConfig } from 'vitepress'

export default defineConfig({
  // GitHub Pages serves this project at https://jotrorox.github.io/arduino.c3l/
  base: '/arduino.c3l/',
  title: 'arduino.c3l',
  description: 'C3 library for Arduino/AVR projects, focused on ATmega328P boards.',
  cleanUrls: true,
  themeConfig: {
    nav: [
      { text: 'Guide', link: '/guide/getting-started' },
      { text: 'API', link: '/api/gpio' },
      { text: 'GitHub', link: 'https://github.com/jotrorox/arduino.c3l' }
    ],

    sidebar: [
      {
        text: 'Guide',
        items: [
          { text: 'Introduction', link: '/' },
          { text: 'Getting Started', link: '/guide/getting-started' },
          { text: 'Blink Example', link: '/guide/blink' },
          { text: 'Build & Flash', link: '/guide/build-and-flash' },
          { text: 'Project Layout', link: '/guide/project-layout' }
        ]
      },
      {
        text: 'API Reference',
        items: [
          { text: 'GPIO', link: '/api/gpio' },
          { text: 'Time', link: '/api/time' },
          { text: 'ADC', link: '/api/adc' },
          { text: 'PWM', link: '/api/pwm' },
          { text: 'UART', link: '/api/uart' },
          { text: 'I2C', link: '/api/i2c' },
          { text: 'Interrupts', link: '/api/interrupts' },
          {
            text: 'Drivers',
            items: [
              { text: 'SSD1306 OLED', link: '/api/drivers/ssd1306' },
              { text: 'LCD1602 I2C', link: '/api/drivers/lcd1602' },
              { text: 'Servo', link: '/api/drivers/servo' },
              { text: 'HC-40 Ultrasonic', link: '/api/drivers/hc40' }
            ]
          }
        ]
      },
    ],

    search: {
      provider: 'local'
    }
  }
})
