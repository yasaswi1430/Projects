import React,{ useState, useEffect, createContext } from 'react'

export const UserContext = createContext({});

const is_auth = () {
  //const [loading, setLoading] = useState(true);
  const [userSession, setUserSession] = useState(true);

  useEffect(() => {
    const fetchUserAuth = async () => {
      try {
        //setLoading(true);
        const res = await fetch('http://localhost:9000/isAuth');
        if (!res.ok) return;// setLoading(false);
        const data = await res.json();
        console.log(data);
        setUserSession(data.);
        //setLoading(false);
      } catch (error) {
        //setLoading(false);
        console.error('There was an error fetch auth', error);
        return;
      }
    }
    fetchUserAuth();
  }, []);

  return (
    <div></div>
  )
}

export default is_auth;