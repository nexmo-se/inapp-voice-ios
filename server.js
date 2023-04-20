require('dotenv').config();
const axios = require('axios');
const cors = require('cors');

const port = process.env.PORT || 3002; 
const express = require('express')
const app = express();
app.use(express.json());
app.use(cors());

const  { Vonage }  = require('@vonage/server-sdk');
const vonage = new Vonage({
    apiKey: process.env.API_KEY,
    apiSecret: process.env.API_SECRET,
    applicationId: process.env.APPLICATION_ID,
    privateKey: process.env.PRIVATE_KEY
})
const { tokenGenerate } = require('@vonage/jwt');


const fs = require('fs')
var privateKey = fs.readFileSync(process.env.PRIVATE_KEY);
const REGIONS = ["virginia", "oregon", "dublin", "frankfurt", "singapore", "sydney"]
const DATA_CENTER = {
  virginia:	"https://api-us-3.vonage.com",
  oregon: "https://api-us-4.vonage.com",
  dublin:	"https://api-eu-3.vonage.com",
  frankfurt:	"https://api-eu-4.vonage.com",
  singapore:	"https://api-ap-3.vonage.com",
  sydney:	"https://api-ap-4.vonage.com"
}

const aclPaths = {
    "paths": {
      "/*/users/**": {},
      "/*/conversations/**": {},
      "/*/sessions/**": {},
      "/*/devices/**": {},
      "/*/image/**": {},
      "/*/media/**": {},
      "/*/applications/**": {},
      "/*/push/**": {},
      "/*/knocking/**": {},
      "/*/legs/**": {}
    }
}

app.post('/register', (req, res) => {
    const {username, region, pin} = req.body;
    if (!username || !region || !pin || pin !== process.env.LOGIN_PIN || !REGIONS.includes(region.toLowerCase())) {
      console.log("missing information error")
      return res.status(501).end()
    }

    const selectedRegion = region.toLowerCase()
    const restAPI = `${DATA_CENTER[selectedRegion]}/v0.3`

    axios.get(`${restAPI}/users?name=${username}`, { headers: {"Authorization" : `Bearer ${generateJwt()}`} })
    .then(async (result) => {
        console.log("user exist")
        const jwt = generateJwt(username) 
        console.log("return 1")
        return res.status(200).json({ username, region, token: jwt});
    })
    .catch(error => {
      axios.post(`${restAPI}/users`, {
        "name":  username,
        "display_name": username
      } , { headers: {"Authorization" : `Bearer ${generateJwt()}`} })
      .then(async (result) => {
        console.log("user not exist")
        const jwt = generateJwt(username)
        console.log("return 2")

        return res.status(200).json({username, region, token: jwt});
      }).catch(error => {
        console.log("register error", error)
          res.status(501).send()
      })      
    })
  });

  function generateJwt(username) {
    if (!username) {
      const adminJwt = tokenGenerate(process.env.APPLICATION_ID, privateKey, {
        //expire in 24 hours
        exp: Math.round(new Date().getTime()/1000)+86400,
        acl: aclPaths
      });
      return adminJwt
    }
    
    const jwt = tokenGenerate(process.env.APPLICATION_ID, privateKey, {
      sub: username,
      //expire in 3 days
      exp: Math.round(new Date().getTime()/1000)+259200,
      acl: aclPaths
      });
  
    return jwt
  }

  app.listen(port, () => console.log(`Listening on port ${port}`)); 
