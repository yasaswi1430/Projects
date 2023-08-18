import React from "react";
import { useEffect , useState} from "react";
import { useNavigate } from "react-router";
import isAuth from "../auth";

function Run_Courses() {
  const [depts, setDepts] = useState([]);
    const [userid,setUserid] = useState(null);
    const [role,setRole] = useState(0);
    //const location = useLocation();
    const url = "/course/running";
    const navigate = useNavigate();
    const [year,setYear] = useState(null);
    const [semester,setSemester] = useState(null);

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
                        setDepts(data.data);
                        setYear(data.year);
                        setSemester(data.sem);
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
        <div className = "h1" ><h1>Current Running Courses</h1></div>
        <h2> <span>{year} , {semester} </span> semester</h2>        
          <table>
              <thead>
                <tr>
                    <th scope="col">#</th>
                    <th scope="col">Department </th>
                    <th scope="col">#Courses Offered</th>
                </tr>
              </thead>
              <tbody>
                { depts.map((dept, i) => (
                  <tr>
                    <th scope="row">{i+1}</th>
                    <td><a href={`/course/running/${dept.dept_name}`}>{dept.dept_name}</a></td>
                    <td>{dept.count}</td>
                  </tr>
                ))}
              </tbody>
          </table>
      </div>
    </div>
  );
}

export default Run_Courses;