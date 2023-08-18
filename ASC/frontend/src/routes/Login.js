import React, {useState} from 'react';
import {useNavigate} from 'react-router-dom';
//import Index from '../index';
//import useFetch from '../useFetch';

function Login() {
    const [values, setValues] = useState( {userid: '',  password: ''} );
    let success = false;
    const navigate = useNavigate();
    const handleChange = (fieldName) => (event) => {
        setValues({ ...values, [fieldName]: event.target.value });
    };


    const handleSubmit = async (event) => {
        event.preventDefault();
        try {
            console.log("maya");
            const res = await fetch('http://localhost:9000/login/', {
                                method: 'POST',
                                'credentials': 'include',
                                headers: {
                                'Content-Type': 'application/json',
                                },
                                body: JSON.stringify( {userid: values.userid, password: values.password} )
                               });
            console.log("here");
            const data = await res.json();
            setValues({userid: '', password: ''});
            if(data.userSession.role>0) {
                console.log('Success');
                success = true;
                console.log(data);
                navigate("/home/",{replace:true});
                return;
            }
            if (!res.ok)  console.log('error');
            return;
        }   catch (error) {
                return console.log(error);
            }
    };
    return (
        <div id="Login">
        <form onSubmit={handleSubmit}>
            <h2>{"   "} Login</h2>
            <div className="input-field">
                <input type="text" name="userid" id="userid" placeholder="Enter User ID"
                 onChange={handleChange('userid')} value={values.userid} required/>
            </div>
            <div className="input-field">
                <input type="password" name="password" id="password" placeholder="Enter Password"
                 onChange={handleChange('password')} value={values.password} required/>
            </div>
            <br/><p></p>
            <input type="submit" value="LogIn"/>
        </form>
        </div>
    );
}

export default Login;