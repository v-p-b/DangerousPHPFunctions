<?php
echo file_get_contents("header.html");
$f=file("php_dangerous.txt");

foreach($f as $l){
    
    if (substr($l,0,1)=="["){
        echo preg_replace("/\[(.*)\]/",'<h3>${1}</h3>',$l);     
    }  else{
        
        $parts=explode('#',$l); 
        $c=trim($parts[0]);
        echo '<p><a href="http://www.php.net/manual/en/function.'.str_replace('_','-',$c).'.php">'.$c.'</a>'.(sizeof($parts)>1?"<i>".$parts[1]."</i>":"").'</p>'."\n";
    }  
       
    
}
echo file_get_contents("footer.html");
?>
