import React from 'react';
import ReactDOM from 'react-dom/client';
import {BrowserRouter} from 'react-router-dom';
import MainRouter from './MainRouter';

function Index() {
  return (
    <BrowserRouter>
      <MainRouter />
    </BrowserRouter>
  );
};

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<Index />);

export default Index;