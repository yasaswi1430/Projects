import React, {useContext} from 'react';
import {Route,Routes} from 'react-router-dom';
//import { UserContext } from './sessions';
import Login from './routes/Login';
import Home from './routes/Home';
import Instructor from './routes/Instructor';
import Run_Courses from './routes/Run_Courses';
import For_Dept_run from './routes/For_Dept_run';
import Course from './routes/Course';
import Registration from './routes/Registration';
//import Course from './routes/Course';

function MainRouter() {
  console.log("MainRouter");
  return (
    <div>
        <Menu />
        <Routes>
            <Route path="/" element={<Login/>} />
            <Route path="/login/" element={<Login/>} />
            <Route path="/home/" element={<Home/>} />
            <Route path="/instructor/:instructor_id/" element={<Instructor/>} />
            <Route path="/course/running/" element={<Run_Courses/>} />
            <Route path="/course/running/:dept_name/" element={<For_Dept_run/>} />
            <Route path="/course/:course_id" element={<Course/>} />
            {<Route path="/home/registration" element={<Registration/>} />
            }
        </Routes>
    </div>
  );
};

function Menu() {
  console.log("Menu");
  return (
    <header>
      <h3>ASC</h3>
    </header>
  );
};


export default MainRouter;