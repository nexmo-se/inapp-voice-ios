import { neru } from 'neru-alpha';
import express from 'express';
import * as dotenv from 'dotenv';
import axios from 'axios';
import cors from 'cors';
import {tokenGenerate} from '@vonage/jwt';
import fs from 'fs';
dotenv.config()

const port = process.env.NERU_APP_PORT || process.env.PORT || 3003; 
const app = express();
app.use(express.json());
app.use(cors());

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

const API_VERSION = 'v0.3'

const applicationId = neru.config.apiApplicationId || process.env.APPLICATION_ID
const privateKey = neru.config.privateKey || fs.readFileSync(process.env.PRIVATE_KEY);

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

app.use(express.static('public'))

app.get('/_/health', async (req, res) => {
    res.sendStatus(200);
});

app.get('/', async (req, res, next) => {
    res.send('hello world').status(200);
});

app.post('/getCredential', (req, res) => {
  const {username, region, pin , token} = req.body;
  if (!username || !region || !(pin || token )|| !REGIONS.includes(region.toLowerCase())) {
    console.log("getCredential missing information error")
    return res.status(501).end()
  }

  if (pin && pin != process.env.LOGIN_PIN) {
    console.log("getCredential wrong pin")
    return res.status(501).end()
  }

  if (token) {
    let tokenDecode = JSON.parse(Buffer.from(token.split('.')[1], 'base64').toString());
  
    if (tokenDecode.application_id !== applicationId) {
      console.log("getCredential wrong token: ", tokenDecode)
      return res.status(501).end()
    }
  }

  const selectedRegion = region.toLowerCase()
  const restAPI = `${DATA_CENTER[selectedRegion]}/${API_VERSION}`
  const websocket = WEBSOCKET[selectedRegion]

  axios.get(`${restAPI}/users?name=${username}`, { headers: {"Authorization" : `Bearer ${generateJwt()}`} })
  .then(async (result) => {
      console.log("user exist", result.data._embedded.users[0].name)
      const jwt = generateJwt(username) 
      return res.status(200).json({ username, userId: result.data._embedded.users[0].id, region, dc: DATA_CENTER[selectedRegion], ws: websocket, token: jwt});
  })
  .catch(error => {
    axios.post(`${restAPI}/users`, {
      "name":  username,
      "display_name": username
    } , { headers: {"Authorization" : `Bearer ${generateJwt()}`} })
    .then(async (result) => {
      console.log("user not exist",result.data.name)
      const jwt = generateJwt(username)

      return res.status(200).json({username, userId: result.data.id, region, dc: DATA_CENTER[selectedRegion], ws: websocket, token: jwt});
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

  if (tokenDecode.application_id !== applicationId) {
    console.log("getMembers wrong token: ", tokenDecode)
    return res.status(501).end()
  }

  const restAPI = `${dc}/${API_VERSION}`

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

app.delete('/deleteUser', async (req, res) => {
  const {dc, userId, token} = req.body;
  if (!dc || !userId || !token) {
    console.log("deleteUser missing information error")
    return res.status(501).end()
  }
  let tokenDecode = JSON.parse(Buffer.from(token.split('.')[1], 'base64').toString());

  if (tokenDecode.application_id !== applicationId) {
    console.log("deleteUser wrong token: ", tokenDecode)
    return res.status(501).end()
  }

  const restAPI = `${dc}/${API_VERSION}`

  try {
    await deleteUser(restAPI, userId)
    return res.status(200).end()
  } catch (error) {
    console.log("deleteuser error:", error)
    return res.status(501).end()
  }
})

app.delete('/deleteAllUsers', (req, res) => {
  const {dc, token} = req.body;
  if (!dc || !token) {
    console.log("deleteAllUsers missing information error")
    return res.status(501).end()
  }
  let tokenDecode = JSON.parse(Buffer.from(token.split('.')[1], 'base64').toString());

  if (tokenDecode.application_id !== applicationId) {
    console.log("deleteAllUsers wrong token: ", tokenDecode)
    return res.status(501).end()
  }

  const restAPI = `${dc}/${API_VERSION}`

  axios.get(`${restAPI}/users?page_size=100`, { headers: {"Authorization" : `Bearer ${generateJwt()}`} })
  .then(async (result) => {
      const memberIds = result.data._embedded.users
        .map((member) => member.id)
      
      memberIds.forEach(async (userId) => {
        try {
          await deleteUser(restAPI, userId)
        } catch (error) {
          console.log("deleteuser error:", error)
        }
      });

      return res.status(200).send();
  })
  .catch(error => {
    console.log("get members error: ", error)
    res.status(501).send()
  })
})

function generateJwt(username) {
  if (!username) {
    const adminJwt = tokenGenerate(applicationId, privateKey, {
      //expire in 24 hours
      exp: Math.round(new Date().getTime()/1000)+86400,
      acl: aclPaths
    });
    return adminJwt
  }
  
  const jwt = tokenGenerate(applicationId, privateKey, {
    sub: username,
    //expire in 3 days
    exp: Math.round(new Date().getTime()/1000)+259200,
    acl: aclPaths
    });

  return jwt
}

function deleteUser(restAPI, userId) {
  return new Promise((resolve, reject) => {
    axios.delete(`${restAPI}/users/${userId}`, { headers: {"Authorization" : `Bearer ${generateJwt()}`} })
    .then(async (result) => {
        console.log("user deleted")
        resolve()
    })
    .catch(error => {
        console.log("delete user error: ", error)
        reject(error)
    })
  })
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
        "action": "connect",
        "ringbackTone":"https://cdn.newvoicemedia.com/webrtc-audio/us-ringback.mp3",
        "endpoint": [
          {
            "type": "app",
            "user": username
          }
        ],
        "timeout": 20
      }
    ]
  }
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
