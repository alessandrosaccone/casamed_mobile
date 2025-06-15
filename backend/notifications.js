const express = require('express');
const pool = require('./db'); // Database connection
const router = express.Router();
const authenticateToken = require('./authMiddleware'); // Authentication middleware

// Endpoint to get notifications for a user
router.get('/notifications', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await pool.query(`
      SELECT 
        id,
        type,
        title,
        message,
        is_read,
        created_at
      FROM notifications
      WHERE user_id = $1
      ORDER BY created_at DESC
      LIMIT 50
    `, [userId]);

    const formattedNotifications = result.rows.map(row => ({
      id: row.id,
      type: row.type,
      title: row.title,
      message: row.message,
      isRead: row.is_read,
      createdAt: row.created_at
    }));

    res.json({ 
      success: true, 
      notifications: formattedNotifications 
    });
  } catch (err) {
    console.error('Errore durante il recupero delle notifiche:', err);
    res.status(500).json({ 
      success: false, 
      message: 'Errore durante il recupero delle notifiche.' 
    });
  }
});

// Endpoint to get unread notifications count
router.get('/notifications/count', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await pool.query(`
      SELECT COUNT(*) as unread_count
      FROM notifications
      WHERE user_id = $1 AND is_read = false
    `, [userId]);

    const unreadCount = parseInt(result.rows[0].unread_count);

    res.json({ 
      success: true, 
      unreadCount: unreadCount 
    });
  } catch (err) {
    console.error('Errore durante il conteggio delle notifiche:', err);
    res.status(500).json({ 
      success: false, 
      message: 'Errore durante il conteggio delle notifiche.' 
    });
  }
});

// Endpoint to mark notification as read
router.put('/notifications/:id/read', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const notificationId = req.params.id;

    const result = await pool.query(`
      UPDATE notifications
      SET is_read = true
      WHERE id = $1 AND user_id = $2
      RETURNING *
    `, [notificationId, userId]);

    if (result.rowCount === 0) {
      return res.status(404).json({ 
        success: false, 
        message: 'Notifica non trovata.' 
      });
    }

    res.json({ 
      success: true, 
      message: 'Notifica segnata come letta.' 
    });
  } catch (err) {
    console.error('Errore durante l\'aggiornamento della notifica:', err);
    res.status(500).json({ 
      success: false, 
      message: 'Errore durante l\'aggiornamento della notifica.' 
    });
  }
});

// Endpoint to mark all notifications as read
router.put('/notifications/read-all', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;

    await pool.query(`
      UPDATE notifications
      SET is_read = true
      WHERE user_id = $1 AND is_read = false
    `, [userId]);

    res.json({ 
      success: true, 
      message: 'Tutte le notifiche sono state segnate come lette.' 
    });
  } catch (err) {
    console.error('Errore durante l\'aggiornamento delle notifiche:', err);
    res.status(500).json({ 
      success: false, 
      message: 'Errore durante l\'aggiornamento delle notifiche.' 
    });
  }
});

// Utility function to create notifications (can be called from other files)
async function createNotification(userId, type, title, message, client = null) {
  const queryClient = client || pool;
  
  try {
    await queryClient.query(`
      INSERT INTO notifications (user_id, type, title, message, created_at)
      VALUES ($1, $2, $3, $4, NOW())
    `, [userId, type, title, message]);
    
    console.log(`Notification created for user ${userId}: ${title}`);
  } catch (error) {
    console.error('Error creating notification:', error);
    throw error;
  }
}

// Export both router and utility function
module.exports = {
  router,
  createNotification
};