<?php
// vpn_manager.php v2.0 — Multi-VPS SSH + Local API
require_once __DIR__.'/config.php';

class VPNManager {

    // ── CREATE via SSH ke VPS target ──────────────────────────
    public static function createAccount($server, $type, $username, $days, $quota=100, $iplimit=2) {
        $username = preg_replace('/[^a-zA-Z0-9_\-]/','', $username);
        if (empty($username)) return ['success'=>false,'message'=>'Username tidak valid'];
        if (!in_array(strtolower($type),['ssh','vmess','vless','trojan','trial']))
            return ['success'=>false,'message'=>'Tipe tidak didukung'];

        $host = $server['host'] ?? '';
        $isLocal = self::isLocalHost($host);

        if ($isLocal) {
            return self::callLocalAPI('create', $type, $username, $days, $quota, $iplimit);
        }
        return self::callRemoteSSH($server, 'create', $type, $username, $days, $quota, $iplimit);
    }

    // ── DELETE — fix: selalu hapus di server tujuan ──────────
    public static function deleteAccount($server, $type, $username) {
        if (empty($username)) return ['success'=>false,'message'=>'Username kosong'];
        $host = $server['host'] ?? '';
        $isLocal = self::isLocalHost($host);

        if ($isLocal) {
            $out = shell_exec(sprintf('sudo %s delete %s %s 2>&1',
                escapeshellcmd(VPN_API_BRIDGE),
                escapeshellarg(strtolower($type)),
                escapeshellarg($username)
            ));
            return json_decode(trim($out??''), true) ?? ['success'=>true];
        }
        return self::callRemoteSSH($server, 'delete', $type, $username);
    }

    // ── TRIAL — buat akun 1 jam ───────────────────────────────
    public static function createTrial($server, $type, $username) {
        // Trial = 1 jam, quota 1GB, ip limit 1
        // Kita simpan sebagai 1 hari di server, expiry di DB = 1 jam dari sekarang
        return self::createAccount($server, $type, $username, 1, 1, 1);
    }

    // ── STATUS SERVER ─────────────────────────────────────────
    public static function checkServerStatus($server) {
        $host = $server['host'] ?? '';
        $port = $server['port'] ?? 22;
        if (self::isLocalHost($host)) {
            $out = shell_exec('sudo '.VPN_API_BRIDGE.' status 2>/dev/null');
            $r = json_decode(trim($out??''), true);
            return ($r['xray']??'') === 'active' ? 'ready' : 'offline';
        }
        // Cek port SSH remote
        $conn = @fsockopen($host, $port, $errno, $errstr, 5);
        if ($conn) { fclose($conn); return 'ready'; }
        return 'offline';
    }

    // ── PROCESS EXPIRED ───────────────────────────────────────
    public static function processExpiredAccounts() {
        $db = getDB();
        // Trial dan akun biasa yang sudah expired
        $stmt = $db->prepare("SELECT va.*, s.host, s.port, s.ssh_user, s.ssh_password, s.ssh_key 
            FROM vpn_accounts va 
            JOIN servers s ON va.server_id = s.id 
            WHERE va.masa_aktif < NOW() AND va.status = 'active'");
        $stmt->execute();
        $expired = $stmt->fetchAll();
        $count = 0;
        foreach ($expired as $acc) {
            self::deleteAccount($acc, $acc['tipe'], $acc['username']);
            $db->prepare("UPDATE vpn_accounts SET status='expired' WHERE id=?")->execute([$acc['id']]);
            $count++;
        }
        return $count;
    }

    // ── PRIVATE: Cek apakah host = lokal ─────────────────────
    private static function isLocalHost($host) {
        $local = ['localhost','127.0.0.1','::1'];
        if (in_array($host, $local)) return true;
        // Bandingkan dengan IP sendiri
        $myIP = trim(shell_exec('curl -s --max-time 3 ifconfig.me 2>/dev/null') ?: '');
        if (!empty($myIP) && $host === $myIP) return true;
        $myIPLocal = trim(shell_exec("hostname -I | awk '{print \$1}' 2>/dev/null") ?: '');
        if (!empty($myIPLocal) && $host === $myIPLocal) return true;
        return false;
    }

    // ── PRIVATE: Panggil lokal vpn-api ───────────────────────
    private static function callLocalAPI($action, $type, $username, $days=0, $quota=100, $iplimit=1) {
        if (!is_executable(VPN_API_BRIDGE) && !file_exists(VPN_API_BRIDGE))
            return ['success'=>false,'message'=>'vpn-api bridge tidak ditemukan'];

        $cmd = sprintf('sudo %s %s %s %s %d %d %d 2>&1',
            escapeshellcmd(VPN_API_BRIDGE),
            escapeshellarg($action),
            escapeshellarg(strtolower($type)),
            escapeshellarg($username),
            (int)$days, (int)$quota, (int)$iplimit
        );
        $output = shell_exec($cmd);
        if (empty($output)) return ['success'=>false,'message'=>'Tidak ada output dari vpn-api'];
        $result = json_decode(trim($output), true);
        if (!is_array($result)) return ['success'=>false,'message'=>'Output tidak valid: '.substr($output,0,300)];
        if (!empty($result['success'])) {
            $result['link_config'] = $result['link_tls'] ?? $result['link_config'] ?? '';
        }
        return $result;
    }

    // ── PRIVATE: SSH ke VPS remote ────────────────────────────
    private static function callRemoteSSH($server, $action, $type, $username, $days=0, $quota=100, $iplimit=1) {
        $host    = $server['host'];
        $port    = $server['port'] ?? 22;
        $sshUser = $server['ssh_user'] ?? 'root';
        $sshKey  = $server['ssh_key'] ?? SSH_KEY_PATH;
        $sshPass = $server['ssh_password'] ?? '';

        // Build remote command — panggil vpn-api di VPS remote
        if ($action === 'create') {
            $remoteCmd = sprintf('sudo /usr/local/bin/vpn-api create %s %s %d %d %d 2>&1',
                escapeshellarg(strtolower($type)),
                escapeshellarg($username),
                (int)$days, (int)$quota, (int)$iplimit
            );
        } elseif ($action === 'delete') {
            $remoteCmd = sprintf('sudo /usr/local/bin/vpn-api delete %s %s 2>&1',
                escapeshellarg(strtolower($type)),
                escapeshellarg($username)
            );
        } else {
            $remoteCmd = 'sudo /usr/local/bin/vpn-api status 2>&1';
        }

        // Coba pakai SSH key dulu, fallback ke sshpass jika ada password
        if (!empty($sshKey) && file_exists($sshKey)) {
            $sshCmd = sprintf(
                'ssh -i %s -o StrictHostKeyChecking=no -o ConnectTimeout=15 -o BatchMode=yes -p %d %s@%s %s 2>&1',
                escapeshellarg($sshKey), (int)$port,
                escapeshellarg($sshUser), escapeshellarg($host),
                escapeshellarg($remoteCmd)
            );
        } elseif (!empty($sshPass) && shell_exec('which sshpass 2>/dev/null')) {
            $sshCmd = sprintf(
                'sshpass -p %s ssh -o StrictHostKeyChecking=no -o ConnectTimeout=15 -p %d %s@%s %s 2>&1',
                escapeshellarg($sshPass), (int)$port,
                escapeshellarg($sshUser), escapeshellarg($host),
                escapeshellarg($remoteCmd)
            );
        } else {
            return ['success'=>false,'message'=>'Tidak ada SSH key atau sshpass untuk koneksi ke '.$host];
        }

        exec($sshCmd, $outputArr, $exitCode);
        $output = implode("\n", $outputArr);

        if ($exitCode !== 0) {
            return ['success'=>false,'message'=>'SSH gagal (exit '.$exitCode.'): '.substr($output,0,300)];
        }

        // Cari baris JSON di output
        $jsonLine = '';
        foreach (array_reverse($outputArr) as $line) {
            $line = trim($line);
            if (strpos($line,'{')===0) { $jsonLine=$line; break; }
        }

        $result = json_decode($jsonLine, true);
        if (!is_array($result)) {
            // SSH berhasil tapi output bukan JSON — anggap sukses untuk delete
            if ($action==='delete') return ['success'=>true,'message'=>'Deleted'];
            return ['success'=>false,'message'=>'Output tidak valid dari remote: '.substr($output,0,300)];
        }
        if (!empty($result['success'])) {
            $result['link_config'] = $result['link_tls'] ?? $result['link_config'] ?? '';
        }
        return $result;
    }
}
