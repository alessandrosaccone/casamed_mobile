const nodemailer = require('nodemailer');


const transporter = nodemailer.createTransport({
  host: 'mail.visitame.it',
  port: 465,
  secure: true, // SSL/TLS usa secure: true
  auth: {
    user: 'no-reply@visitame.it',
    pass: 'AhQKgdvkZERTk8x5LxZ8' // inserisci qui la tua password
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








