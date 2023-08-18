var http = require('http');
const pg = require('pg');
const express = require('express');
const cookieParser = require("cookie-parser");
const expressSession = require('express-session');
const mydb = require('./db');
const pgSession = require('connect-pg-simple')(expressSession);
const bcrypt = require("bcryptjs")
const cors = require('cors');
const { equal } = require('assert');
const saltRounds = 10
require('dotenv').config({path: __dirname + '/config.txt'});

const pgPool = new mydb.Pool({
    host: process.env.HOST,
    port: process.env.PORT,
    user: process.env.USER, 
    password: process.env.PASSWORD,
    database: process.env.DATABASE
});

const app = express();
const NODEPORT = process.env.NODEPORT || 9000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());

const corsOptions = {
    origin: 'http://localhost:3000',
    optionsSuccessStatus: 200,
    credentials: true
};
app.use(cors(corsOptions));


// creating 1 hour from milliseconds
const oneHour = 1000 * 60 * 60;

//session middleware
app.use(expressSession({
    secret: process.env.SESSION_SECRET,
    saveUninitialized: false,
    cookie: { 
        secure: false,
        httpOnly: true,
        maxAge: oneHour },
    resave: false,
    store: new pgSession({
        pool: pgPool,
        createTableIfMissing: true
    })
}));

//serving public file
app.use(express.static(__dirname + '/public'));

//-----------------------Middleware-----------------------//
app.use(function (req, res, next) { // authenticating middleware
    console.log(req.method, req.url);
    next('route');
});


app.get('/isAuth', async (req,res) => {
    console.log(req.session);
    if(req.session.userSession) {
        let userid = req.session.userSession.userid;
        let role = req.session.userSession.role;
        return res.json({'userid': userid, 'role': role});
    }
    else return res.status(401).json({userid: null, role: 0});
});

app.get('/', (req,res) => {
    res.redirect('/home');
});


app.get('/home/', (req,res) => {
    console.log(req.session);
    uid = req.session.userSession.userid;
    var getstud, getStudCurrCourses, sem, year,getprevcourses;
    //query_result = "Welcome to home page, <a href='/logout'>click to logout</a><br>";
    mydb.getStudent(uid)
    .then(result => {
        console.log("-------getstud");
        //console.log(result);
        getstud = result;
        return mydb.currentSemester();
    })
    .then(result => {
        sem = result.semester; year = result.year;
        return mydb.getCurSemCourses(uid);
    })
    .then(result => {
        console.log("-----getstudCOURSES",result);
        //console.log(result);
        getStudCurrCourses = result;
        //console.log(getStudCurrCourses);
        console.log("hello")
        return mydb.getPrevSemCourses(uid);
    })
    .then(result => {
        //console.log(result);
        getprevcourses = result.ordered_prevcourses;
        res.json({'getstud':getstud, 'getstudcourses':getStudCurrCourses, 'sem':sem, 'year':year,
            'prevcourses': getprevcourses,
        });
    })
    

});


app.get('/login/', (req,res) => {
        res.redirect('/home');
});

//------------NEEDS TO BE DONE WITH HASHING ETC ETC -----------------//
app.post('/login/',(req,res) => {
    console.log(req.url);
    const {userid,password} = req.body;
    
    if(!userid || !password) return res.status(400).json({msg : "empty userid or password", auth_val: false});
    else mydb.getPassword(userid)
            .then(result => {
                console.log(password);
                if(result) return bcrypt.compare(password, result.hashed_password);
                else return false;
            })
            .then(cmp => {
                console.log("whats prob");
                if(cmp){                 
                    mydb.getRole(userid).then( role_num => {
                        const userSession = {userid: userid, role: role_num};
                        req.session.userSession = userSession;
                        console.log(req.session);
                        return res.status(200).json({userSession});
                    });
                }
                else{
                    console.log("here");
                    res.status(400).json({msg : "Password wrong", auth_val: false});
                }
            });
});

app.get('/logout', async (req,res) => {
    try {
        await req.session.destroy()
        return res.sendStatus(200)
    } catch (e) {
        console.error(e)
        return res.sendStatus(500)
    }
});

app.get('/course/running/', (req,res) => {
    var data, year,sem;
    mydb.currentSemester()
    .then( result => {
        year = result.year; sem = result.semester;
        console.log(result);
        return mydb.Dept_run_course();
    })
    .then(result => {
        return res.json({'data':result,'year':year,'sem':sem});
    })
    // mydb.getRunningCourses()
    // .then(result => {
    //     query_result += "<h1> Prerequisites</h1>: <br>";
    //     for (let row of result) {
    //         query_result += row.course_id + " | " + row.title + " | " + row.credits + "<a href='/course/"+row.course_id+"'>Details</a><br>";
    //     }
    //     res.send(query_result);
    // })
});

app.get('/drop/:course_id', (req,res) => {
    mydb.dropCurrCourse(req.session.userSession.userid,req.params.course_id)
    .then(result => {
        res.status(200).json({msg: "Drop Successful!"});
    })
});

app.get('/course/:course_id', (req,res) => {
    var c_info,c_prq, c_inst;
    mydb.getCourse(req.params.course_id)
    .then(result => {
        c_info = result;
        return mydb.getCoursePrereqs(req.params.course_id);
    })
    .then(result => {
        c_prq = result;
        return mydb.getCurrInstForCourse(req.params.course_id);
    })
    .then(result => {
        c_inst = result;
        console.log("c_info",c_info);
        console.log("c_prq", c_prq);
        console.log("c_inst", c_inst);
        res.json({'c_info': c_info, 'c_prq': c_prq, 'c_inst': c_inst});
    });
});


app.get('/course/running/:dept_name', (req,res) => {
    var year,sem,d_courses;
    mydb.currentSemester()
    .then(result => {
        year = result.year; sem = result.semester;
        return mydb.getRunningCoursesDept(req.params.dept_name);
    })
    .then(result => {
        d_courses = result;
        console.log("d_courses", d_courses);
        console.log("result",result);
        res.json({'data':d_courses, 'year': year, 'semester': sem, 'dept_name': req.params.dept_name});
    })
});

app.get('/instructor/:instructor_id', (req,res) => {
    var inst, currcourses;
    console.log(req.params.instructor_id);
    mydb.getInstructor(req.params.instructor_id)
    .then(result => {
        console.log(result);
        inst = result;
        return mydb.getInstCurrCourses(req.params.instructor_id);
    })
    .then(result => {
        currcourses = result;
        return mydb.getInstPrevCourses(req.params.instructor_id);
    })
    .then(result => {
        console.log(result);
        console.log(currcourses);
        console.log(inst);
        res.json({'inst':inst[0], 'currcourses': currcourses, 'prevcourses': result});
    })
});


app.get('/home/registration', (req,res) => {
    uid = req.session.userSession.userid;
  
    mydb.getStudentRegInfo(uid)
    .then(result => {
        console.log(result);
        res.send(result);
    })
  });
  
  app.get('/home/registration/search/:str', (req,res) => {
    uid = req.session.userSession.userid;
  
    mydb.CourseSearch(uid,req.params.str)
    .then(result => {
        console.log("search", result);
        res.send(result);
    })
  });
  
  app.get('/home/registration/:course_id/:sec_id', (req,res) => {
    uid = req.session.userSession.userid;
  
    mydb.RegisterCourse(uid, req.params.course_id, req.params.sec_id)
    .then(result => {
        console.log(result);
        res.send(result);
    })
  });



app.get('*', (req, res) => {
    res.sendFile('public/error.html',{root: __dirname});
});

app.listen(NODEPORT, () => console.log(`Server Running at port ${NODEPORT}`));
module.exports = {app};