import React, {useState,useEffect} from 'react';
import {useNavigate,Link} from 'react-router-dom';
import isAuth from '../auth';
import {useLocation} from 'react-router-dom';

function Home() {
    const [userid,setUserid] = useState(null);
    const [role,setRole] = useState(0);
    const location = useLocation();
    const url = location.pathname;
    const [student , setStudent] = useState([]);
    const [semester , setSemester] = useState([]);
    const [year , setYear] = useState([]);
    const [courses, setCourses] = useState([]);
    const [prevcourses , setPrevcourses ] = useState([]);
    const navigate = useNavigate();
    const fetch_data = async () => {
        let result = await isAuth();
        setUserid(result.userid);  setRole(result.role);
        console.log(userid,role);
        console.log("result",result)
        if(result.role < 1) {navigate("/login/",{replace:true}); return;}
        if(result.role == 1) {
            fetch("http://localhost:9000"+url, {credentials: 'include'})
                    .then( res => {
                        if(!res.ok) console.log(error);
                        return res.json();
                    })
                    .then( data => {
                        setStudent(data.getstud);
                        setCourses(data.getstudcourses);
                        setSemester(data.sem); setYear(data.year);
                        setPrevcourses(data.prevcourses);
                        console.log("happy");
                    });
        };  
    }
    useEffect(() => {
        fetch_data();
    }, []);
    //console.log(userid,role);

    const dropCourse = (course_id) => (event) => {
        /* NEED TO HANDLE */
        fetch('http://localhost:9000/drop/'+course_id, {credentials: 'include'})
            .then( res => {
                if(!res.ok) console.log(error);
                return res.json();
            })
        navigate("/home/",{replace:true}); return;
    }

    if(role > 1) { //instructor
        return <h1>Faculty!</h1>;
    }
    else { //student
        return (
            <div className = "home">
            <Link to="/home/registration" id="reg_link">Registration</Link>
                <div className = "container">
                        <div className = "h1" >Home <br/>Name :  <span>{student.name}</span>, ID : <span>{student.id}</span></div>
                        <div className = "h2" >Department : <span>{student.dept_name}</span></div>
                        <div className = "h2" >Total Credits Taken : <span>{student.tot_cred}</span></div>
                      </div>
                       <div><span></span><span>&zwnj;</span><span></span></div>
                          <div className = "h2" id="text1">Current Courses &nbsp; | &nbsp; <span>{semester}, {year}</span></div>
                          <table>
                            <thead>
                              <tr>
                                  <th scope="col">#</th>
                                  <th scope="col">Course ID</th>
                                  <th scope="col">Title</th>
                                  <th scope="col">Department</th>
                                  <th scope="col">Credits</th>
                                  <th scope="col"> Drop </th>
                              </tr>
                            </thead>
                            <tbody>
                              { courses.map((course, i) => (
                                <tr>
                                  <th scope="row">{i+1}</th>
                                  <td><a href={`/course/${course.course_id}`}>{course.course_id}</a></td>
                                  <td>{course.title}</td>
                                  <td>{course.dept_name}</td>
                                  <td>{course.credits}</td>
                                  <td><button className="btn btn-danger" onClick={dropCourse(course.course_id)}>Drop</button></td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                          <div className = "h2" id="text2">Previous Undertaken Courses</div>
                      <div><span></span><span>&zwnj;</span><span></span></div>
                      {prevcourses.map((sem , i) => (
                          <div>
                          <div className = "h2" id="text3"><span className = "text-success">{sem.semester}, {sem.year}</span></div>
                          <table className="table table-bordered table-striped mytable">
                            <thead className="thead-dark">
                              <tr>
                                  <th scope="col">#</th>
                                  <th scope="col">Course ID</th>
                                  <th scope="col">Title</th>
                                  <th scope="col">Department</th>
                                  <th scope="col">Credits</th>
                                  <th scope="col">Grade</th>
                              </tr>
                            </thead>
                            <tbody>
                              { sem.courses.map((course, i) => (
                                <tr>
                                  <th scope="row">{i+1}</th>
                                  <td><a href={`/course/${course.course_id}`}>{course.course_id}</a></td>
                                  <td>{course.title}</td>
                                  <td>{course.dept_name}</td>
                                  <td>{course.credits}</td>
                                  <td>{course.grade}</td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                          </div>
                        )
                      )
                        }
            </div>
          );
    }
}
export default Home;