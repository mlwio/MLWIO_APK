const express = require('express');
const cors = require('cors');
const { MongoClient, ServerApiVersion } = require('mongodb');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json());

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/mlwio_users';

const client = new MongoClient(MONGODB_URI, {
  serverApi: {
    version: ServerApiVersion.v1,
    strict: true,
    deprecationErrors: true,
  }
});

let db;
let usersCollection;

async function connectToDatabase() {
  try {
    await client.connect();
    db = client.db('mlwio_users');
    usersCollection = db.collection('users');
    console.log('✅ Connected to MongoDB successfully');
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
    process.exit(1);
  }
}

app.get('/api/users/:gmail', async (req, res) => {
  try {
    const { gmail } = req.params;
    const user = await usersCollection.findOne({ gmail });
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json(user);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/users', async (req, res) => {
  try {
    const { gmail } = req.body;
    
    const existingUser = await usersCollection.findOne({ gmail });
    if (existingUser) {
      return res.json(existingUser);
    }
    
    const newUser = {
      gmail,
      coins: 0,
      isPremium: false,
      premiumExpiryDate: null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    
    const result = await usersCollection.insertOne(newUser);
    newUser._id = result.insertedId;
    
    res.status(201).json(newUser);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.patch('/api/users/:gmail/coins', async (req, res) => {
  try {
    const { gmail } = req.params;
    const { coins } = req.body;
    
    const result = await usersCollection.updateOne(
      { gmail },
      {
        $set: {
          coins,
          updatedAt: new Date().toISOString(),
        },
      }
    );
    
    if (result.matchedCount === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/users/:gmail/coins/add', async (req, res) => {
  try {
    const { gmail } = req.params;
    const { amount } = req.body;
    
    const result = await usersCollection.updateOne(
      { gmail },
      {
        $inc: { coins: amount },
        $set: { updatedAt: new Date().toISOString() },
      }
    );
    
    if (result.matchedCount === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/users/:gmail/coins/deduct', async (req, res) => {
  try {
    const { gmail } = req.params;
    const { amount } = req.body;
    
    const user = await usersCollection.findOne({ gmail });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    if (user.coins < amount) {
      return res.status(400).json({ error: 'Insufficient coins' });
    }
    
    const result = await usersCollection.updateOne(
      { gmail },
      {
        $inc: { coins: -amount },
        $set: { updatedAt: new Date().toISOString() },
      }
    );
    
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/users/:gmail/premium/activate', async (req, res) => {
  try {
    const { gmail } = req.params;
    const { days, coinCost, expiryDate } = req.body;
    
    const user = await usersCollection.findOne({ gmail });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    if (user.coins < coinCost) {
      return res.status(400).json({ error: 'Insufficient coins' });
    }
    
    const result = await usersCollection.updateOne(
      { gmail },
      {
        $inc: { coins: -coinCost },
        $set: {
          isPremium: true,
          premiumExpiryDate: expiryDate,
          updatedAt: new Date().toISOString(),
        },
      }
    );
    
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/users/:gmail/premium/downgrade', async (req, res) => {
  try {
    const { gmail } = req.params;
    
    const result = await usersCollection.updateOne(
      { gmail },
      {
        $set: {
          isPremium: false,
          premiumExpiryDate: null,
          updatedAt: new Date().toISOString(),
        },
      }
    );
    
    if (result.matchedCount === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/users/check-expired', async (req, res) => {
  try {
    const now = new Date().toISOString();
    
    const result = await usersCollection.updateMany(
      {
        isPremium: true,
        premiumExpiryDate: { $lt: now },
      },
      {
        $set: {
          isPremium: false,
          premiumExpiryDate: null,
          updatedAt: now,
        },
      }
    );
    
    res.json({
      success: true,
      downgraded: result.modifiedCount,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

connectToDatabase().then(() => {
  app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`📡 API endpoint: http://localhost:${PORT}/api`);
  });
});

process.on('SIGINT', async () => {
  await client.close();
  console.log('\n👋 MongoDB connection closed');
  process.exit(0);
});
