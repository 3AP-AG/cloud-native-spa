import React from 'react';
import logo from './logo.svg';
import './App.css';
import { env } from "./env";

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <div>
          <h2>Environment variables</h2>
          <pre style={{textAlign: "left"}}>{JSON.stringify(env, null, 4)}</pre>
        </div>
      </header>
    </div>
  );
}

export default App;
