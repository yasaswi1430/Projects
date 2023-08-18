require('dotenv').config({path: __dirname + '/config.txt'});

// ----- postgresql connection client -----
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.HOST,
  port: process.env.PORT,
  user: process.env.USER, 
  password: process.env.PASSWORD,
  database: process.env.DATABASE
});

async function getPool() {
    return pool;
}


async function getStudent(uid){
    let result;
    try{
        result =  await pool.query('SELECT * from student WHERE id = $1 ;', [uid]);
        return result.rows[0];
    }
    catch(error){
        console.log("Error executing query!\n");
    } 
}


async function getInstructor(uid){
    let result;
    try{
        result = await  pool.query('SELECT * from instructor WHERE id = $1 ;', [uid]);
        console.log("inst:",result);
        return result.rows;
    }
    catch(error){
        console.log("Error executing query!\n");
    }
}

async function getStudCourses(uid){
    let result;
    try{
        result = await pool.query('SELECT * from takes NATURAL JOIN course WHERE id = $1 ORDER BY year desc , semester desc;', [uid]);
        return result.rows;
    }catch(error){
        console.log("Error executing query!\n");
    }
}

async function getInstCourses(uid){
    let result;
    try{
        result = await pool.query('SELECT * from teaches NATURAL JOIN course WHERE id = $1 ORDER BY year desc, semester desc;', [uid]);
        return result.rows;
    }catch(error){
        console.log("Error executing query!\n");
    }
}

async function getInstCurrCourses(uid) {
    let result;
    try{
        res1 = await currentSemester();
        year = res1.year; sem = res1.semester;
        result = await pool.query('SELECT * from teaches NATURAL JOIN course WHERE id = $1 and year = $2 and semester = $3 ORDER BY course_id;', [uid,year,sem]);
        return result.rows;
    }catch(error){
        console.log("Error executing query!\n");
        console.log(error);        
    }
}

async function getDeptCourses(dept){
    let result;
    try{
        result = await  pool.query('SELECT * from course WHERE dept_name = $1 ORDER BY course_id;', [dept]);
        return result.rows;
    }catch(error){
        console.log("Error executing query!\n");
    }
}


async function getRunningCourses(){
    let result;
    try{
        result = await currentSemester();
        cur_yr = result.year;
        cur_sem = result.semester;

        result = await pool.query('SELECT * from course WHERE course_id IN (SELECT course_id from section WHERE year = $1 AND semester = $2 ORDER BY course_id);', [cur_yr, cur_sem]);
        return result.rows;
    }catch(error){
        console.log("Error executing query!\n");
        console.log(error);        
    }
}

async function getRunningCoursesDept(dept_name){
    let result;
    try{
        result = await currentSemester();
        cur_yr = result.year;
        cur_sem = result.semester;

        result = await pool.query('SELECT * from section NATURAL JOIN course WHERE dept_name = $1 AND year = $2 AND semester = $3 ORDER BY course_id, sec_id;', [dept_name, cur_yr, cur_sem]);
        console.log("How here",result.rows);
        return result.rows;
    }catch(error){
        console.log("Error executing query!\n");
        console.log(error);        
    }
    
}

async function getCourse(course_id){
    let result;
    try{
        result = await pool.query('SELECT * from course WHERE course_id = $1;', [course_id]);
        return result.rows[0];
    }catch(error){
        console.log("Error executing query!\n");
        console.log(error);        
    }
}

async function getCoursePrereqs(course_id){
    let result;
    try{
        result  = await pool.query('SELECT * from prereq JOIN course on prereq.prereq_id = course.course_id WHERE prereq.course_id = $1;', [course_id]);
        return result.rows;
    }catch(error){
        console.log("Error executing query!\n");
        console.log(error);        
    }
}

async function currentSemester(){
    let result, max_yr, max_sem;
    
    try{
        result = await pool.query('SELECT max(year) as year from section');
        max_yr = result.rows[0].year;
    }catch(error){
        console.log("Error executing query!\n");
        console.log(error);        
    }

    try{
        result = await pool.query('SELECT semester from section WHERE year = $1', [max_yr]);
        max_sem = '';
        DICT = {};
        DICT['Spring'] = 1;
        DICT['Summer'] = 2;
        DICT['Fall'] = 3;
        DICT['Winter'] = 4;
        max_sem = result.rows[0].semester;
        for(let i = 1; i < result.rows.length; i++){
            if(DICT[result.rows[i].semester] > DICT[max_sem]){
                max_sem = result.rows[i].semester;
            }
        }
        let res = {year: max_yr, semester: max_sem}
        //console.log(res);
        return res;
    }catch(error){
        console.log("Error executing query!\n");
    }
}


async function updatePassword(uid, hashed_pswd, delete_old = true){
    let result;
    let pass_exists;
    try{
        result = await pool.query('SELECT * from user_password WHERE id = $1;', [uid])
        if(result.rows.length != 0){
            //delete old password
            if(!delete_old) return 1;
            try{
                result = await pool.query('DELETE from user_password WHERE id = $1;', [uid]);
            }catch(error){
                console.log("Error deleting password!\n");
            }  
        }

        // insert password
        try{
            result = await pool.query('INSERT into user_password values ($1,$2) ;', [uid,hashed_pswd]);
            return 0;
        }catch(error){
            console.log("Error updating password!\n");
        }

    }catch(error){
        console.log("Error executing query!\n");
    }
}



async function getPassword(uid){
    let result;
    try{
        result = await pool.query('SELECT * from user_password WHERE id = $1;', [uid]);
        return result.rows[0];
    }catch(error){
        console.log("Error executing query!\n");
    }
}

async function getRole(uid){
    let role;
    try{
        res1 = await pool.query('SELECT * from instructor WHERE id = $1;', [uid]);
        if (res1.rowCount > 0) return 2;
        else return 1;
        //console.log(res1);
    }catch(error){
        console.log("Error executing query!\n");
    }
}

async function getCurSemCourses(uid){
    let result;
    try{
        res1 = await currentSemester();
        year = res1.year; sem = res1.semester;
        result = await pool.query('SELECT * from takes NATURAL JOIN course WHERE id = $1 and year = $2 and semester = $3 ORDER BY course_id;', [uid,year,sem]);
        console.log(result.rows);
        return result.rows;
    }catch(error){
        console.log("Error executing query!\n");
    }
}

async function getPrevSemCourses(uid) {
    let data = {prevcourses: '', ordered_prevcourses: ''};
    try{
        res1 = await currentSemester();
        cur_yr = res1.year; cur_sem = res1.year;
        result = await pool.query('SELECT * from takes NATURAL JOIN course WHERE id = $1 AND year <= $2 ORDER BY year,semester,course_id;', [uid, cur_yr]);
        data.prevcourses = result.rows;
        order = ['Spring', 'Summer', 'Fall', 'Winter']
        pref = {}
        for(let i = 0; i < order.length; i++){
            pref[order[i]] = i;
        }
        for(let i = 0; i < data.prevcourses.length; i++){
            data.prevcourses[i].semorder = pref[data.prevcourses[i].semester];
            if(data.prevcourses[i].year == cur_yr && data.prevcourses[i].semorder >= pref[cur_sem]){
                data.prevcourses.splice(i, 1);
                i--;
            }
        }
        data.prevcourses.sort(function(a, b){
            if(a.year == b.year){
                return a.semorder == b.semorder ? a.course_id - b.course_id :  b.semorder - a.semorder;
            }   
            return b.year - a.year;
        });
        data.ordered_prevcourses = [];
        let tmpyr;
        let tmpsem;
        let a=-1;
        for(let i = 0; i < data.prevcourses.length; i++){
            if(data.prevcourses[i].year != tmpyr || data.prevcourses[i].semester != tmpsem){
                tmpyr = data.prevcourses[i].year;
                tmpsem = data.prevcourses[i].semester;
                if(a>=0)data.ordered_prevcourses.push({year : tmpyr, semester : tmpsem, courses : []});
                else {a=0;}
            }
            if(data.ordered_prevcourses.length > 0)
              data.ordered_prevcourses[data.ordered_prevcourses.length - 1].courses.push(data.prevcourses[i]);
        } 
        return data;
    }catch(error){
        console.log("Error executing query!\n");
        console.log(error);
    }
}

async function dropCurrCourse(uid,c_id) {
    let result;
    try{
        res1 = await pool.query('DELETE from takes WHERE id = $1 and course_id = $2;', [uid,c_id]);
    }catch(error){
        console.log("Error executing query!\n");
        console.log(error);        
    }
}

async function getInstPrevCourses(uid) {
    let result;
    try{
        res = await currentSemester();
        year = res.year; sem = res.semester;
        res1 = await pool.query('(SELECT * from teaches NATURAL JOIN course WHERE id = $1 ORDER BY year desc, semester desc) EXCEPT (SELECT * from teaches NATURAL JOIN course WHERE id = $1 and year = $2 and semester = $3) ORDER BY year desc, semester desc;', [uid,year,sem]);
        return res1.rows;
    }catch(error){
        console.log("Error executing query!\n");
        console.log(error);        
    }
}

async function Dept_run_course() {
    let result,year,res;
    try{
        res = await currentSemester();
        year = res.year; sem = res.semester;
        res1 = await pool.query('SELECT dept_name,count(*) as count from section NATURAL JOIN course WHERE year = $1 and semester = $2 GROUP BY dept_name ORDER BY dept_name;', [year,sem]);
        return res1.rows;
    }catch(error){
        console.log("Error executing query!\n");
        console.log(error);        
    }
}

async function getCurrInstForCourse(cid) {
    let result,year,res;
    try{
        res = await currentSemester();
        year = res.year; sem = res.semester;
        res1 = await pool.query('SELECT * from teaches NATURAL JOIN instructor WHERE course_id = $3 and year = $1 and semester = $2 ORDER BY name;', [year,sem,cid]);
        console.log("res1.rows",res1.rows);
        return res1.rows;
    }catch(error){
        console.log("Error executing query!\n");
        console.log(error);        
    }
}

async function getStudentRegInfo(id){
    let result;
    var data = {};
    try{
  
      result = await pool.query('SELECT * from instructor WHERE id = $1;', [id]);
      if(result.rows.length != 0){
          data.INS = true;
          data.INSID = id;
      }
  
        result = await pool.query('SELECT * from student WHERE id = $1;', [id]);
        if(result.rows.length == 0){
            data.valid = false;
            return data;
        }
        data.valid = true;
        data.student = result.rows[0];
  
        result = await currentSemester();
        cur_yr = result.year;
        cur_sem = result.semester;
  
        data.semester = cur_sem;
        data.year = cur_yr;
  
        result = await pool.query('SELECT * from section NATURAL JOIN course WHERE year = $1 AND semester = $2 ORDER BY course_id;', [cur_yr, cur_sem]);
        for(let i = 0; i < result.rows.length; i++){
            result.rows[i].id = result.rows[i].course_id;
        }
        
        if( result.rows.length > 0 ) result.rows[0].sections = [result.rows[0].sec_id];
        for(let i = 1; i < result.rows.length; i++){
            if(result.rows[i].course_id == result.rows[i-1].course_id){
                result.rows[i-1].sections.push(result.rows[i].sec_id);
                result.rows.splice(i, 1);
                i--;
            }
            else{
                result.rows[i].sections = [result.rows[i].sec_id];
            }
        }
  
        data.courses = result.rows;
  
        return data;
    }catch(error){
        console.log("Error executing query!\n");
        console.log(error);
    }
  
}
  
async function CourseSearch(id,str){
    let result;
    var data = {};
    try{
        result = await pool.query('SELECT * from student WHERE id = $1;', [id]);
        if(result.rows.length == 0){
            data.valid = false;
            return data;
        }
        data.valid = true;
        data.student = result.rows[0];
  
        result = await currentSemester();
        cur_yr = result.year;
        cur_sem = result.semester;
  
        data.semester = cur_sem;
        data.year = cur_yr;
  
        str = '%' + str + '%';
  
        result = await pool.query('SELECT * from section NATURAL JOIN course WHERE year = $1 AND semester = $2 AND (course_id ilike $3 OR title ilike $3 OR dept_name ilike $3) ORDER BY course_id;', [cur_yr, cur_sem, str]);
        for(let i = 0; i < result.rows.length; i++){
            result.rows[i].id = result.rows[i].course_id;
        }
        
        if( result.rows.length > 0 ) result.rows[0].sections = [result.rows[0].sec_id];
        for(let i = 1; i < result.rows.length; i++){
            if(result.rows[i].course_id == result.rows[i-1].course_id){
                result.rows[i-1].sections.push(result.rows[i].sec_id);
                result.rows.splice(i, 1);
                i--;
            }
            else{
                result.rows[i].sections = [result.rows[i].sec_id];
            }
        }
  
        data.courses = result.rows;
  
        return data;
    }catch(error){
        console.log("Error executing query!\n");
        console.log(error);
    }
  
}
  
async function RegisterCourse(id,course_id,sec_id){
    let result;
    var data = {};
    try{
  
        result = await currentSemester();
        cur_yr = result.year;
        cur_sem = result.semester;
  
        data.semester = cur_sem;
        data.year = cur_yr;
  
        //student check
        result = await pool.query('SELECT * from student WHERE id = $1;', [id]);
        if(result.rows.length == 0){
            data.valid = false;
            data.logout = true;
            data.msg = "Invalid Student ID!";
            return data;
        }
  
        //register check
        result = await pool.query('SELECT * from takes WHERE id = $1 AND course_id = $2 AND semester = $3 AND year = $4;', [id, course_id, cur_sem, cur_yr]);
        if(result.rows.length > 0){
            data.valid = false;
            data.msg = "Already registered for this course!";
            return data;
        }
  
        //section | course check
        result = await pool.query('SELECT * from section WHERE course_id = $1 AND sec_id = $2 AND year = $3 AND semester = $4;', [course_id, sec_id, cur_yr, cur_sem]);
        if(result.rows.length == 0){
            data.valid = false;
            data.msg = "Invalid Section!";
            return data;
        }
        else{
            course_requested = result.rows[0];
        }
  
        //prereq check..
        result = await pool.query('SELECT prereq_id from prereq WHERE course_id = $1;', [course_id]);
        prereqs = result.rows;
        for(let i = 0; i < prereqs.length; i++){
            result = await pool.query('SELECT * from takes WHERE id = $1 AND course_id = $2;', [id, prereqs[i].prereq_id]);
            if(result.rows.length == 0){
                data.valid = false;
                data.msg = `Prerequisite : ${prereqs[i].prereq_id}  not satisfied!`;
                return data;
            }
        }
  
        // slot crash check
        result = await pool.query('SELECT * from takes NATURAL JOIN section WHERE id = $1 AND year = $2 AND semester = $3;', [id, cur_yr, cur_sem]);
        for(let i = 0; i < result.rows.length; i++){
            if(result.rows[i].time_slot_id == course_requested.time_slot_id){
                data.valid = false;
                data.msg = "Time slot clash! with "  + result.rows[i].course_id;
                return data;
            }
        }
  
        //UPDATE STUDENT CREDITS
        result = await pool.query("INSERT INTO takes VALUES($1, $2, $3, $4, $5, '--' );", [id, course_id, sec_id, cur_sem, cur_yr]);
        result = await pool.query("UPDATE student SET tot_cred = tot_cred + (SELECT credits from course WHERE course_id = $1) WHERE id = $2;", [course_id, id]);
  
        data.valid = true;
  
        return getStudentRegInfo(id);
  
    }
    catch(error){
        console.log("Error executing query!\n");
        console.log(error);
    }
  
}
  
  

//async function 
    
module.exports = { getRole, Pool, getStudent, 
    getInstructor, getStudCourses, 
    getInstCourses, getDeptCourses, 
    getCourse, getCoursePrereqs, 
    currentSemester , updatePassword , 
    getPassword, getRunningCourses,
    getRunningCoursesDept,
    getCurSemCourses, getPrevSemCourses, dropCurrCourse, getInstPrevCourses, Dept_run_course,
    getInstCurrCourses, getCurrInstForCourse,
    getStudentRegInfo,
    CourseSearch,
    RegisterCourse,
};