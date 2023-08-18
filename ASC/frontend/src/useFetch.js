import { useState, useEffect } from "react";

const useFetch = (url) => {
  const [data, setData] = useState(null);

  useEffect(() => {
    async function fetch_data() {
      console.log("happy");
      res = await fetch("http://localhost:9000"+url);
      if(!res.ok) console.log(error);
      else {
        console.log("Working");
        data = await res.json();
        console.log(data);
        setData(data);
      }
    }
    fetch_data();
  }, [url]);

  return [data];
};

export default useFetch;