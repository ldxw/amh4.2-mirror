<?php

class upload extends AmysqlController
{
	function UpBlobData()
	{
		if(!isset($_FILES['Filedata']['tmp_name'])) exit();
		$this -> _class('Functions');
		$FieldName = $_GET['FieldName'];
		$TableName = $_GET['TableName'];
		$DatabaseName = $_GET['DatabaseName'];
		$where = $_GET['where'];

		$data = bin2hex(fread(fopen($_FILES['Filedata']['tmp_name'], 'r'), $_FILES['Filedata']['size']));
		$sql = "UPDATE `$DatabaseName`.`$TableName` SET `$FieldName` = 0x$data WHERE $where";
		$this ->  _model('indexs') -> _query($sql);
		echo '<i>BLOB - ' . Functions::CountSize($_FILES['Filedata']['size']) . '</i>';
		exit();
	}
}