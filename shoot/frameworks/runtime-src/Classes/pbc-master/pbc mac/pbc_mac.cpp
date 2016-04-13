/*
 *  pbc_mac.cpp
 *  pbc mac
 *
 *  Created by 梁清风 on 16/3/17.
 *  Copyright © 2016年 ztgame. All rights reserved.
 *
 */

#include <iostream>
#include "pbc_mac.hpp"
#include "pbc_macPriv.hpp"

void pbc_mac::HelloWorld(const char * s)
{
	 pbc_macPriv *theObj = new pbc_macPriv;
	 theObj->HelloWorldPriv(s);
	 delete theObj;
};

void pbc_macPriv::HelloWorldPriv(const char * s) 
{
	std::cout << s << std::endl;
};

