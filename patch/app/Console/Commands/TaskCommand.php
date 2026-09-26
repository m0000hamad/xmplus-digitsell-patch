<?php
namespace App\Console\Commands;

use Psr\Container\ContainerInterface;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

final class TaskCommand extends Command
{
    protected function configure(): void
    {
        parent::configure();

        $this->setName('job:run');
		
        $this->setDescription('Run Cron Job');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {		
		ini_set('memory_limit', '-1');
		
		$scheduler = new \Jobby\Jobby();

		$scheduler->add('ServerCommand', array(
			'command' => 'php '.BASE_PATH.'/xmplus serverstatus',
			'schedule' => "*/5 * * * *",
			'output' => BASE_PATH.'/storage/logs/serverstatus.log',
			'lock_dir' => BASE_PATH.'/storage/cron/',
			'enabled' => true,
		));

		$scheduler->add('ResetCommand', array(
			'command' => 'php '.BASE_PATH.'/xmplus datareset',
			'schedule' => "0 0 * * *",
			'output' => BASE_PATH.'/storage/logs/datareset.log',
			'lock_dir' => BASE_PATH.'/storage/cron/',
			'enabled' => true,
		));

		$scheduler->add('LogsCommand', array(
			'command' => 'php '.BASE_PATH.'/xmplus clearlogs',
			'schedule' => "0 */6 * * *",
			'output' => BASE_PATH.'/storage/logs/clearlogs.log',
			'lock_dir' => BASE_PATH.'/storage/cron/',
			'enabled' => true,
		));

		$scheduler->add('BackupCommand', array(
			'command' => 'php '.BASE_PATH.'/xmplus backup',
			'schedule' => "0 */1 * * *",
			'output' => BASE_PATH.'/storage/logs/backup.log',
			'lock_dir' => BASE_PATH.'/storage/cron/',
			'enabled' => true,
		));

		$scheduler->add('UserCommand', array(
			'command' => 'php '.BASE_PATH.'/xmplus userstatus',
			'schedule' => "*/2 * * * *",
			'output' => BASE_PATH.'/storage/logs/userstatus.log',
			'lock_dir' => BASE_PATH.'/storage/cron/',
			'enabled' => true,
		));

		$scheduler->add('QueueCommand', array(
			'command' => 'php '.BASE_PATH.'/xmplus queue',
			'schedule' => "*/10 * * * *",
			'output' => BASE_PATH.'/storage/logs/queue.log',
			'lock_dir' => BASE_PATH.'/storage/cron/',
			'enabled' => true,
		));

		$scheduler->add('VersionCommand', array(
			'command' => 'php '.BASE_PATH.'/xmplus check_update',
			'schedule' => "0 */1 * * *",
			'output'  => BASE_PATH.'/storage/logs/check_update.log',
			'lock_dir' => BASE_PATH.'/storage/cron/',
			'enabled' => true,
		));

		// the console command list lives in the encoded bootstrap, so the
		// commission payout is scheduled as a plain script instead
		$scheduler->add('CommissionJob', array(
			'command' => 'php '.BASE_PATH.'/bin/commissions.php',
			'schedule' => "* * * * *",
			'output' => BASE_PATH.'/storage/logs/commissions.log',
			'lock_dir' => BASE_PATH.'/storage/cron/',
			'enabled' => true,
		));

		// paid time plans are granted here, because the order pipeline that
		// would normally do it is encoded
		$scheduler->add('TimePlanJob', array(
			'command' => 'php '.BASE_PATH.'/bin/timeplans.php',
			'schedule' => "* * * * *",
			'output' => BASE_PATH.'/storage/logs/timeplans.log',
			'lock_dir' => BASE_PATH.'/storage/cron/',
			'enabled' => true,
		));

		// one-time gift for joining the Telegram channel; asks the Bot API who is a member
		$scheduler->add('TgJoinJob', array(
			'command' => 'php '.BASE_PATH.'/bin/tgjoin.php',
			'schedule' => "* * * * *",
			'output' => BASE_PATH.'/storage/logs/tgjoin.log',
			'lock_dir' => BASE_PATH.'/storage/cron/',
			'enabled' => true,
		));

		// tells the customer on Telegram that a redeemed gift card was applied;
		// /portal/redeem is encoded, so this reads giftcard_logs
		$scheduler->add('GiftCardNotifyJob', array(
			'command' => 'php '.BASE_PATH.'/bin/giftcards.php',
			'schedule' => "* * * * *",
			'output' => BASE_PATH.'/storage/logs/giftcards.log',
			'lock_dir' => BASE_PATH.'/storage/cron/',
			'enabled' => true,
		));

		// promotions on subscription plans: prizes, closing, list prices back
		$scheduler->add('PromoJob', array(
			'command' => 'php '.BASE_PATH.'/bin/promos.php',
			'schedule' => "* * * * *",
			'output' => BASE_PATH.'/storage/logs/promos.log',
			'lock_dir' => BASE_PATH.'/storage/cron/',
			'enabled' => true,
		));

		$scheduler->run();
		return 0;
    }
}
	