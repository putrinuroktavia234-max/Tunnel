  <!DOCTYPE html>
  <html lang="en">
  <head>
      <meta charset="UTF-8">
      <title>OrderVPN Dashboard</title>
      <script src="https://cdn.tailwindcss.com"></script>
  </head>
  <body class="bg-gray-100">
      <div class="container mx-auto p-6">
          <h1 class="text-3xl font-bold mb-6">OrderVPN
  Dashboard</h1>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div class="bg-white p-4 shadow rounded-lg">
                  <h2 class="text-xl font-semibold">Total
  Users</h2>
                  <p class="text-2xl font-bold">0</p>
              </div>
              <div class="bg-white p-4 shadow rounded-lg">
                  <h2 class="text-xl font-semibold">Server
  Status</h2>
                  <p class="text-green-500
  font-bold">Online</p>
              </div>
          </div>
      </div>
  </body>
  </html>
  EOF

  # Membuat file koneksi
  cat <<EOF > /root/ordervpn_web/api/config.php
  <?php
  $host = 'localhost';
  $db   = 'ordervpn_db';
  $user = 'root';
  $pass = '';
  $conn = new mysqli($host, $user, $pass, $db);
  if ($conn->connect_error) { die("Connection failed: " .
  $conn->connect_error); }
  ?>
  EOF
