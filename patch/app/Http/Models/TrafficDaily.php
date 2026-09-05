<?php

namespace App\Http\Models;

final class TrafficDaily extends Model
{
    protected $connection = 'default';
    protected $table = 'traffic_daily';
	protected $guarded = ['id'];
	public $timestamps = false;
}
