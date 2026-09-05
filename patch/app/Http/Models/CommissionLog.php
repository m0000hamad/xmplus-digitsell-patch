<?php

namespace App\Http\Models;

final class CommissionLog extends Model
{
    protected $connection = 'default';
    protected $table = 'commission_log';
	protected $guarded = ['id'];
	public $timestamps = false;
}
