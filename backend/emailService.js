const nodemailer = require('nodemailer');

// Configurazione del trasportatore SMTP
const transporter = nodemailer.createTransport({
  host: 'smtp.eu.sparkpostmail.com',
  port: 587,
  secure: false, // Nessuna crittografia
  auth: {
    user: 'SMTP_Injection',
    pass: '2c5033cfc6023f2dc9099ea3df86110fc35f3c50'
  }
});

// Funzione per inviare l'email di verifica
const sendVerificationEmail = async (email, verificationLink) => {
  const mailOptions = {
    from: 'no-reply@visitame.it',
    to: email,
    subject: 'Please verify your email',
    text: `Click on this link to verify your email: ${verificationLink}`,
    html: `<p>Click on this <a href="${verificationLink}">link</a> to verify your email.</p>`
  };

  await transporter.sendMail(mailOptions);
  console.log(`Verification email sent to ${email}`);
};

// Funzione per inviare l'email di recupero password
const sendPasswordResetEmail = async (email, resetLink) => {
  const mailOptions = {
    from: 'no-reply@visitame.it',
    to: email,
    subject: 'Password Reset Request',
    text: `Click on this link to reset your password: ${resetLink}`,
    html: `<p>Click on this <a href="${resetLink}">link</a> to reset your password.</p>`
  };

  await transporter.sendMail(mailOptions);
  console.log(`Password reset email sent to ${email}`);
};

module.exports = { sendVerificationEmail, sendPasswordResetEmail };








