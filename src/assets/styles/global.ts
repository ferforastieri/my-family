import { createGlobalStyle } from 'styled-components';

export const GlobalStyle = createGlobalStyle`
  * {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
  }

  html, body {
    height: 100%;
    width: 100%;
    overflow-x: hidden;
  }

  body {
    font-family: 'Pacifico', Arial, sans-serif;
    -webkit-font-smoothing: antialiased;
    background: linear-gradient(180deg, #fff8fa 0%, #fff0f5 100%);
    position: relative;
  }

  #root {
    display: flex;
    min-height: 100vh;
    position: relative;
    overflow-x: hidden;
  }

  button {
    cursor: pointer;
  }

  a {
    text-decoration: none;
    color: inherit;
  }

  /* Fix para iOS */
  @supports (-webkit-touch-callout: none) {
    body, #root {
      min-height: -webkit-fill-available;
    }
  }

  /* Fix para scroll mobile */
  @media (max-width: 768px) {
    body {
      overflow-y: auto;
      -webkit-overflow-scrolling: touch;
    }
  }
`; 