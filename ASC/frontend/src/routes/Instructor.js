import React, {useState,useEffect} from 'react';
import {useNavigate,useLocation} from 'react-router-dom';
import isAuth from '../auth';

function Instructor() {
    const [userid,setUserid] = useState(null);
    const [role,setRole] = useState(0);
    const location = useLocation();
    const url = location.pathname;
    const [courses, setCourses] = useState([]);
    const [prevcourses , setPrevcourses ] = useState([]);
    const [instructor , setInstructor] = useState([]);
    const [semester , setSemester] = useState([]);
    const [year , setYear] = useState([]);
    const navigate = useNavigate();

    const fetch_data = () => {
        isAuth().then(result => {
            setUserid(result.userid);  setRole(result.role);
            if(result.role > 0) {
                fetch("http://localhost:9000"+url, {credentials: 'include'})
                    .then( res => {
                        if(!res.ok) console.log(error);
                        return res.json();
                    })
                    .then( data => {
                        console.log("Data",data);
                        setInstructor(data.inst);
                        setCourses(data.currcourses);
                        setSemester(data.inst.sem);
                        setPrevcourses(data.prevcourses);
                        console.log("happy");
                    });
            }
            if(result.role < 1) {navigate("/login/",{replace:true}); return;}
        });  
    }
    useEffect(() => {
        fetch_data();
    }, []);
    console.log(userid,role);
    //console.log(data);
  
  return (
    <div className= "home">
        <div>
        <div className = "container my_top">
                <div className = "h1" >Instructor Page <br/> Prof. <span>{instructor.name}</span></div>
                <div className = "h2" >Department <span>{instructor.dept_name}</span></div>
              </div>
               <div><span></span><span>&zwnj;</span><span></span></div>
                  <div className = "h2" >Teaching Courses <span>{semester}, {year}</span></div>
              </div>
                  <table>
                    <thead>
                      <tr>
                          <th scope="col">#</th>
                          <th scope="col">Course ID</th>
                          <th scope="col">Section ID</th>
                          <th scope="col">Title</th>
                      </tr>
                    </thead>
                    <tbody>
                      { courses.map((course, i) => (
                        <tr>
                          <th scope="row">{i+1}</th>
                          <td><a href={`/course/${course.course_id}`}>{course.course_id}</a></td>
                          <td>{course.title}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                  <div className = "h2" >Courses Taught Previously</div>
                  <table>
                    <thead>
                      <tr>
                          <th scope="col">#</th>
                          <th scope="col">Year</th>
                          <th scope="col">Semester</th>
                          <th scope="col">Course ID</th>
                          <th scope="col">Title</th>
                      </tr>
                    </thead>
                    <tbody>
                      { prevcourses.map((course, i) => (
                        <tr>
                          <th scope="row">{i+1}</th>
                          <td>{course.year}</td>
                          <td>{course.semester}</td>
                          <td><a href={`/course/${course.course_id}`}>{course.course_id}</a></td>
                          <td>{course.title}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
             </div>
  );
}

export default Instructor;