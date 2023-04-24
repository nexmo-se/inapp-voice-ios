require('dotenv').config();
const axios = require('axios');
const cors = require('cors');

const port = process.env.PORT || 3003; 
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

const WEBSOCKET = {
  virginia:	"wss://ws-us-3.vonage.com",
  oregon:	"wss://ws-us-4.vonage.com",
  dublin: "wss://ws-eu-3.vonage.com",
  frankfurt:	"wss://ws-eu-4.vonage.com",  
  singapore:	"wss://ws-ap-3.vonage.com",
  sydney:	"wss://ws-ap-4.vonage.com"
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

app.post('/getCredential', (req, res) => {
  const {username, region, pin} = req.body;
  if (!username || !region || !pin || pin !== process.env.LOGIN_PIN || !REGIONS.includes(region.toLowerCase())) {
    console.log("getCredential missing information error")
    return res.status(501).end()
  }

  const selectedRegion = region.toLowerCase()
  const restAPI = `${DATA_CENTER[selectedRegion]}/v0.3`
  const websocket = WEBSOCKET[selectedRegion]

  axios.get(`${restAPI}/users?name=${username}`, { headers: {"Authorization" : `Bearer ${generateJwt()}`} })
  .then(async (result) => {
      console.log("user exist")
      const jwt = generateJwt(username) 
      return res.status(200).json({ username, region, dc: DATA_CENTER[selectedRegion], ws: websocket, token: jwt});
  })
  .catch(error => {
    axios.post(`${restAPI}/users`, {
      "name":  username,
      "display_name": username
    } , { headers: {"Authorization" : `Bearer ${generateJwt()}`} })
    .then(async (result) => {
      console.log("user not exist")
      const jwt = generateJwt(username)

      return res.status(200).json({username, region, dc: DATA_CENTER[selectedRegion], ws: websocket, token: jwt});
    }).catch(error => {
      console.log("register error", error)
        res.status(501).send()
    })      
  })
});

app.post('/getMembers', (req, res) => {
  const {dc, username, token} = req.body;
  if (!dc || !username || !token) {
    console.log("getMembers missing information error")
    return res.status(501).end()
  }
  let tokenDecode = JSON.parse(Buffer.from(token.split('.')[1], 'base64').toString());

  if (tokenDecode.application_id !== process.env.APPLICATION_ID) {
    console.log("getMembers wrong token: ", tokenDecode)
    return res.status(501).end()
  }

  const restAPI = `${dc}/v0.3`

  axios.get(`${restAPI}/users?page_size=100`, { headers: {"Authorization" : `Bearer ${generateJwt()}`} })
  .then(async (result) => {
      const membersName = result.data._embedded.users
        .filter((member) => member.name !== username)
        .map((member) => member.name)
      
      return res.status(200).json({members: membersName});
  })
  .catch(error => {
    console.log("get members error: ", error)
    res.status(501).send()
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

app.get('/voice/answer', (req, res) => {
  console.log('NCCO request:');
  console.log(`  - caller: ${req.query.from}`);
  console.log(`  - callee: ${req.query.to}`);
  console.log('---');
  var ncco = [{"action": "talk", "text": "No destination user - hanging up"}];
  var username = req.query.to;
  if (username) {
    ncco = [
      {
        "action": "talk",
        "text": "Connecting you to " + username
      },
      {
        "action": "connect",
        "endpoint": [
          {
            "type": "app",
            "user": username
          }
        ]
      }
    ]
  }
  console.log("json ", ncco)
  res.json(ncco);
});

app.all('/voice/event', (req, res) => {
  console.log('EVENT:');
  console.dir(req.body);
  console.log('---');
  res.sendStatus(200);
});

// TODO: clean up user

app.listen(port, () => console.log(`Listening on port ${port}`)); 
