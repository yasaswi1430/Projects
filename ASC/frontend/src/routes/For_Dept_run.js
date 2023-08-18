import React from "react";
import { useEffect , useState} from "react";
import { useNavigate, useLocation } from "react-router";
import isAuth from "../auth";


function For_Dept_run() {
    const [userid,setUserid] = useState(null);
    const [role,setRole] = useState(0);
  const [courses, setCourses] = useState([]);
  const [dept_name, setDept_name] = useState(null);
  const [semester, setSemester] = useState(null);
  const [year, setYear] = useState(null);
  const location = useLocation();
  const url = location.pathname;
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
                        setCourses(data.data); setDept_name(data.dept_name);
                        setYear(data.year); setSemester(data.sem);
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

  return (
    <div className = "home">
        <div className = "container">
              <div className = "h1"><h3>Running Courses</h3> <span>{dept_name} </span> Department</div>
            </div>
              <h2> <span>{year} , {semester} </span> semester</h2>       
                <table>
                    <thead>
                      <tr>
                          <th scope="col">#</th>
                          <th scope="col">Course ID</th>
                          <th scope="col">Title</th>
                          <th scope="col">Credits</th>
                      </tr>
                    </thead>
                    <tbody>
                      { courses.map((course, i) => (
                        <tr>
                          <th scope="row">{i+1}</th>
                          <td><a href={`/course/${course.course_id}`}>{course.course_id}</a></td>
                          <td>{course.title}</td>
                          <td>{course.credits}</td>
                        </tr>
                      ))}
                    </tbody>
                </table>
    </div>
  );
}

export default For_Dept_run;