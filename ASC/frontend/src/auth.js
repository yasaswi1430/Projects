async function isAuth() {
    const url = "/isAuth";
    const res = await fetch('http://localhost:9000'+url, { credentials: 'include' });
    let data = await res.json();
    console.log(data);
    return data;
}

export default isAuth;