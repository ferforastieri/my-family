import { createGlobalStyle } from 'styled-components';

export const GlobalStyle = createGlobalStyle`
  * {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
  }

  html, body, #root {
    height: 100%;
    width: 100%;
  }

  body {
    font-family: 'Pacifico', Arial, sans-serif;
    -webkit-font-smoothing: antialiased;
    background: linear-gradient(180deg, #fff8fa 0%, #fff0f5 100%);
  }

  #root {
    display: flex;
  }

  button {
    cursor: pointer;
  }

  a {
    text-decoration: none;
    color: inherit;
  }
`; 