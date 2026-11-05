<?php
// Native ORM and Smarty regression. Only connection-local temporary tables.
if (PHP_SAPI !== 'cli') exit(1);
$panel = $argv[1]; $source = $argv[2];
require $panel . '/vendor/autoload.php';
require $source . '/app/Tickets/Lifecycle.php';
require $source . '/app/Tickets/Builder.php';
require $source . '/app/Http/Models/Ticket.php';
require $panel . '/bin/console.php';
use Illuminate\Database\Capsule\Manager as DB;
use App\Http\Models\Ticket;
$pdo = DB::connection()->getPdo();
$ddl = $pdo->query('SHOW CREATE TABLE tickets')->fetch(PDO::FETCH_NUM)[1];
$pdo->exec(str_replace('CREATE TABLE', 'CREATE TEMPORARY TABLE', $ddl));
$pdo->exec('CREATE TEMPORARY TABLE ticket_close_notice(ticketid BIGINT PRIMARY KEY,userid BIGINT,created BIGINT,mail_sent INT,telegram_sent INT)');
function check($yes, $what) { if (!$yes) throw new RuntimeException($what); echo "PASS $what\n"; }
function fixture($id, $root, $when, $status=1) {
    $row = ['id'=>$id,'title'=>'Fixture','content'=>"line 1\nline 2",'department'=>'other','files'=>'',
        'main_id'=>$root ?: $id,'rootid'=>$root,'userid'=>900001,'username'=>'fixture','datetime'=>$when,
        'status'=>$status,'state'=>0,'user_message_id'=>'','admin_message_id'=>'','telegram_id'=>''];
    DB::table('tickets')->insert($row);
}
function denied(callable $fn, $what) {
    try { $fn(); } catch (RuntimeException $e) { check(true,$what); return; }
    throw new RuntimeException('Not denied: '.$what);
}
fixture(1,0,time()-172801); fixture(2,0,time()-172799); fixture(3,0,time()-200000); fixture(4,3,time()-30); fixture(5,0,time(),0);
check(Ticket::find(1)->isClosed(), 'expired at 48 hours');
check(!Ticket::find(2)->isClosed(), 'open before deadline');
check(!Ticket::find(3)->isClosed(), 'recent reply resets deadline');
denied(function(){Ticket::where('id',5)->update(['status'=>1]);}, 'builder cannot reopen closed ticket');
denied(function(){ $t=Ticket::find(5);$t->status=1;$t->save();}, 'model cannot reopen closed ticket');
denied(function(){ $t=new Ticket(['rootid'=>1,'main_id'=>1,'userid'=>900001,'datetime'=>time()]); $t->save();},'expired thread rejects new reply');
check(App\Tickets\Lifecycle::closeDue()===1, 'cron closes exactly one expired thread');
check(App\Tickets\Lifecycle::closeDue()===0, 'cron is idempotent');
check(DB::table('ticket_close_notice')->count()===1, 'durable single notification');
check((int)Ticket::find(3)->status===1, 'active thread preserved');
denied(function(){App\Tickets\Lifecycle::validateAttachment('../config.php',900001);}, 'reject path traversal');
denied(function(){App\Tickets\Lifecycle::validateAttachment('tk_900002_'.str_repeat('a',48).'.png',900001);},'reject foreign attachment');
// Exercise notification enqueue without sending anything to external services.
$pdo->exec('CREATE TEMPORARY TABLE user(id BIGINT PRIMARY KEY,username TEXT,email TEXT,telegram_id TEXT)');
$pdo->exec("INSERT INTO user VALUES(900001,'fixture','fixture@example.invalid','')");
$pdo->exec('CREATE TEMPORARY TABLE settings(name VARCHAR(100),value TEXT)');
$pdo->exec("INSERT INTO settings VALUES('maildriver','1'),('telegram','0')");
$pdo->exec('CREATE TEMPORARY TABLE queue_messages(to_email TEXT,subject TEXT,telegramid TEXT,template TEXT,`array` TEXT,time BIGINT)');
require_once $source . '/app/Jobs/TicketJob.php';
(new App\Jobs\TicketJob)->dispatch();
check(DB::table('queue_messages')->count()===1,'email queued once without external delivery');
(new App\Jobs\TicketJob)->dispatch();
check(DB::table('queue_messages')->count()===1,'completed notification not enqueued again');
check((int)DB::table('ticket_close_notice')->value('telegram_sent')===1,'unconnected Telegram skipped');
$smarty = new Smarty();
$smarty->setTemplateDir($source . '/view');
$compile=sys_get_temp_dir().'/ticket-smarty-'.getmypid();mkdir($compile);$smarty->setCompileDir($compile);
foreach (['user/ticket/view.tpl','admin/tickets/view.tpl','user/ticket/open.tpl','user/ticket/ticket.tpl','common/ticketchat.tpl','common/ticketattachment.tpl','common/ticketupload.tpl'] as $path) {
 $t=$smarty->createTemplate($path);$t->compileTemplateSource();check(true,'Smarty '.$path);
}
foreach(glob($compile.'/*') as $f)unlink($f);rmdir($compile);
