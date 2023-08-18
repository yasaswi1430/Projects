import React from "react";
import { useEffect , useState} from "react";
import { useNavigate, useLocation } from "react-router";
import isAuth from "../auth";

function Course() {
    const [course, setCourse] = useState([]);
  const [prereqs, setPrereqs] = useState([]);
  const [inst , setInst] = useState([]);
    const [userid,setUserid] = useState(null);
    const [role,setRole] = useState(0);
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
                        setInst(data.c_inst);
                        setCourse(data.c_info);
                        setPrereqs(data.c_prq);
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
    console.log(course);
  
  return (
    <div className = "home">
        <div className = "container my_top">
          <div className = "h1" >Course ID: <span>{course.course_id}</span> <br/>Title:  <span>{course.title}</span> <br/>  <span >{course.credits}</span> Credits</div>
          </div>
            { prereqs.length > 0 ?
              <div className="container">
              <div><span></span><span>&zwnj;</span><span></span></div>
                    <div className = "h2" >Course Prerequisites</div>
                    <table>
                      <thead>
                        <tr>
                            <th scope="col">#</th>
                            <th scope="col">Course ID</th>
                            <th scope="col">Title</th>
                        </tr>
                      </thead>
                      <tbody>
                        { prereqs.map((prq, i) => (
                          <tr>
                            <th scope="row">{i+1}</th>
                            <td><a href={`/course/${prq.course_id}`}>{prq.course_id}</a></td>
                            <td>{prq.title}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
              </div>
                :
                <div className = "h2" >Prerequisites : <span> None </span></div>
            } 
            { inst.length > 0 ?
            <div>
                <div><span></span><span>&zwnj;</span><span></span></div>
                      <div className = "h2" >Course Instructors</div>
                      <table>
                        <thead>
                          <tr>
                              <th scope="col">#</th>
                              <th scope="col">Instructor ID</th>
                              <th scope="col">Name</th>
                              <th scope="col">Department</th>
                              <th scope="col">Section</th>
                          </tr>
                        </thead>
                        <tbody>
                          { inst.map((instr, i) => (
                            <tr>
                              <th scope="row">{i+1}</th>
                              <td><a href={`/instructor/${instr.id}`}>{instr.id}</a></td>
                              <td>{instr.name}</td>
                              <td>{instr.dept_name}</td>
                              <td>S{instr.sec_id}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                </div>
            :
                  <div className = "h1" >Course NOT running in Current Semester</div>
            }
    </div>
  );
}

export default Course;