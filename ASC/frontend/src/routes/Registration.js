import React from "react";
import { useEffect , useState } from "react";
import { useNavigate } from "react-router-dom";
import Dropdown from 'react-bootstrap/Dropdown';
import { Button, ButtonGroup } from "react-bootstrap";


function Registration() {

  const [courses, setCourses] = useState([]);
  const [student , setStudent] = useState([]);
  const [semester , setSemester] = useState([]);
  const [year , setYear] = useState([]);
  const [msg , setMsg] = useState("Click the button to Register");
  const [search, setSearch] = useState([]);

  const navigate = useNavigate();

  useEffect(() => {

          fetch(`http://localhost:9000/home/registration`, { credentials: 'include' })
            .then(response => {
              return response.json();
            })
            .then(data => {
              if(data.INS){
                navigate(`/instructor/${data.INSID}`);
              }
              else{
                if(data.valid){
                  console.log("data", data);
                  setCourses(data.courses);
                  setStudent(data.student);
                  setSemester(data.semester);
                  setYear(data.year);
                }
                else{
                  navigate("/course/running");
                }
              }
            }
          );

  }, []);

  function register_course(course_id, sec_id){
    return () => {
      fetch(`http://localhost:9000/home/registration/${course_id}/${sec_id}`, { credentials: 'include' })
        .then(response => {
          return response.json();
        })
        .then(data => {
          if(data.msg){
            setMsg(data.msg);
          }
          else{
            setCourses(data.courses);
            setStudent(data.student);
            setSemester(data.semester);
            setYear(data.year);
            setMsg("Click the button to Register");
          }
      }
      );
    }
  }

  function getcourses(){
    fetch(`http://localhost:9000/home/registration/search/${search}`, { credentials: 'include' })
      .then(response => {
        return response.json();
      })
      .then(data => {
          setCourses(data.courses);
      }
    );
  }

  async function searchhandler(e){
    e.preventDefault();
    setSearch(e.target.value);
    console.log("seting search", search);
    await getcourses();
  }

  function setsection(i, section_id){
    courses[i].sec_id = section_id;
    console.log(courses[i].sec_id)
  }

  return (
    <div className = "registration">


        <div class = "container">

              <div class = "container mt-4 mb-3">
                <div class = "h1 text-center text-dark" >Registration {semester}, {year} | Name : <span class = "text-danger">{student.name}</span> | ID : <span class = "text-danger">{student.id}</span></div>
                <div class = "h2 text-center text-dark" >Department : <span class = "text-primary">{student.dept_name}</span></div>
                <div class = "h2 text-center text-dark" >Total Credits Taken : <span class = "text-primary">{student.tot_cred}</span></div>
              </div>
              
               <div class="divider"><span></span><span>&zwnj;</span><span></span></div>



               <div class = "container mt-4 mb-3">
                <div class = "h1 text-center text-danger" >{msg}</div>
              </div>

              <div class="position-relative mb-5">
                  <i class="fa fa-search position-absolute"></i>
                  <input class="form-control" type="search" placeholder="Search for courses" onChange={searchhandler} onInput={searchhandler} ></input>
              </div>



               <div class = "row justify-content-center">
                  <table class="table table-bordered table-striped mytable">
                      <tr class = "bg-primary">
                          <th scope="col">#</th>
                          <th scope="col">Course ID</th>
                          <th scope="col">Title</th>
                          <th scope="col">Department</th>
                          <th scope="col">Section</th>
                          <th scope="col">Credits</th>
                          <th scope="col">Register</th>
                      </tr>

                    <tbody>
                      { courses.map((course, i) => (
                        <tr>
                          <th scope="row">{i+1}</th>
                          <td><a href={`/course/${course.course_id}`}>{course.course_id}</a></td>
                          <td>{course.title}</td>
                          <td>{course.dept_name}</td>
                          <td align="center">

                          <Dropdown as={ButtonGroup}>

                              <Button variant="success">Section</Button>

                              <Dropdown.Toggle split variant="success" id="dropdown-split-basic">
                                S{course.sec_id}
                              </Dropdown.Toggle>

                            <Dropdown.Menu>{
                                course.sections.map((section) => (
                                  <Dropdown.Item href="#" onClick={() => setsection(i,section)}>S{section}</Dropdown.Item>
                                ))
                            }</Dropdown.Menu>
                          </Dropdown>

                          </td>
                          <td>{course.credits}</td>
                          <td><button class="btn btn-warning" onClick={register_course(course.course_id,course.sec_id)}>Register</button></td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
              </div>


        </div>

    </div>
  );
}

export default Registration;