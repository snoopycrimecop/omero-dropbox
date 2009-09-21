#!/usr/bin/env python

"""
   Utility classes for generating file-system-like events
   for testing.

   Copyright 2009 Glencoe Software, Inc. All rights reserved.
   Use is subject to license terms supplied in LICENSE.txt

"""

import exceptions
import logging
import monitors
import os
import tempfile
import threading
import time
import unittest

from uuid import uuid4
from path import path
from omero_ext.functional import wraps
from test.drivers import *

class TestDrivers(unittest.TestCase):
    """
    Simple test to test the testing functionality (driver)
    """

    def setUp(self):
        self.client = MockMonitorClient()
        self.driver = Driver(self.client)

    def assertEventCount(self, count):
        self.assertEquals(count, len(self.client.events))

    def testCallback(self):
        l = []
        self.driver.add(CallbackEvent(1, lambda: l.append(True)))
        self.driver.run()
        self.assertEquals(1, len(l))
        self.assertEventCount(0) # Events don't get passed on callbacks

    def testInfo(self):
        self.driver.add(InfoEvent(1, monitors.EventInfo()))
        self.driver.run()
        self.assertEventCount(1)

class TestSimulator(unittest.TestCase):
    """
    Simple test to test the testing functionality (simulator)
    """

    def beforeMethod(self):
        self.uuid = str(uuid4())
        self.dir = path(tempfile.gettempdir()) / "test-omero" / self.uuid
        self.dir.makedirs()
        self.sim = Simulator(self.dir)
        self.driver = Driver(self.sim)

    def tearDown(self):
        self.assertEquals(0, len(self.driver.errors))

    def assertErrors(self, count = 1):
        self.assertEquals(count, len(self.driver.errors))
        for i in range(count):
            self.driver.errors.pop()

    def testRelativeTest(self):
        self.beforeMethod()
        self.assertTrue(self.sim.isrelto(self.dir / "foo"))
        self.assertTrue(self.sim.isrelto(self.dir / "foo" / "bar" / "baz"))
        # Not relative
        self.assertFalse(self.sim.isrelto(path("/")))
        self.assertFalse(self.sim.isrelto(path("/root")))
        self.assertFalse(self.sim.isrelto(path(".")))

    def testBad(self):
        self.beforeMethod()
        self.driver.add(InfoEvent(1, monitors.EventInfo("foo", monitors.EventType.Create)))
        self.driver.run()
        self.assertErrors()

    def testSimpleCreate(self):
        self.beforeMethod()
        self.driver.add(InfoEvent(1, monitors.EventInfo(self.dir / "foo", monitors.EventType.Create)))
        self.driver.run()

    def testBadCreate(self):
        self.beforeMethod()
        self.driver.add(InfoEvent(1, monitors.EventInfo(self.dir / "foo", monitors.EventType.Create)))
        self.driver.add(InfoEvent(1, monitors.EventInfo(self.dir / "foo", monitors.EventType.Create)))
        self.driver.run()
        self.assertErrors()

    def testBadModify(self):
        self.beforeMethod()
        self.driver.add(InfoEvent(1, monitors.EventInfo(self.dir / "foo", monitors.EventType.Modify)))
        self.driver.run()
        self.assertErrors()

    def testSimpleModify(self):
        self.beforeMethod()
        self.driver.add(InfoEvent(1, monitors.EventInfo(self.dir / "foo", monitors.EventType.Create)))
        self.driver.add(InfoEvent(1, monitors.EventInfo(self.dir / "foo", monitors.EventType.Modify)))
        self.driver.run()

    def testBadDelete(self):
        self.beforeMethod()
        self.driver.add(InfoEvent(1, monitors.EventInfo(self.dir / "foo", monitors.EventType.Delete)))
        self.driver.run()
        self.assertErrors()

    def testSimpleDelete(self):
        self.beforeMethod()
        self.driver.add(InfoEvent(1, monitors.EventInfo(self.dir / "foo", monitors.EventType.Create)))
        self.driver.add(InfoEvent(1, monitors.EventInfo(self.dir / "foo", monitors.EventType.Delete)))
        self.driver.run()

    def testSimpleDeleteWithModify(self):
        self.beforeMethod()
        self.driver.add(InfoEvent(1, monitors.EventInfo(self.dir / "foo", monitors.EventType.Create)))
        self.driver.add(InfoEvent(1, monitors.EventInfo(self.dir / "foo", monitors.EventType.Modify)))
        self.driver.add(InfoEvent(1, monitors.EventInfo(self.dir / "foo", monitors.EventType.Delete)))
        self.driver.run()

    def testDirectoryMethods(self):
        self.beforeMethod()
        self.driver.add(InfoEvent(1, monitors.EventInfo(self.dir / "foo", monitors.EventType.Create)))
        self.driver.add(InfoEvent(1, monitors.EventInfo(self.dir / "foo", monitors.EventType.Modify)))
        self.driver.add(InfoEvent(1, monitors.EventInfo(self.dir / "foo", monitors.EventType.Delete)))
        self.driver.run()

    def testDirectoryMethods(self):
        self.beforeMethod()
        self.driver.add(DirInfoEvent(1, monitors.EventInfo(self.dir / "dir", monitors.EventType.Create)))
        self.driver.add(DirInfoEvent(1, monitors.EventInfo(self.dir / "dir", monitors.EventType.Modify)))
        self.driver.add(DirInfoEvent(1, monitors.EventInfo(self.dir / "dir", monitors.EventType.Delete)))
        self.driver.run()

    def testDirectoryDoesntExistOnModify(self):
        self.beforeMethod()
        self.driver.add(DirInfoEvent(1, monitors.EventInfo(self.dir / "dir", monitors.EventType.Modify)))
        self.driver.run()
        self.assertErrors()

    def testDirectoryDoesntExistOnDelete(self):
        self.beforeMethod()
        self.driver.add(DirInfoEvent(1, monitors.EventInfo(self.dir / "dir", monitors.EventType.Delete)))
        self.driver.run()
        self.assertErrors()

if __name__ == "__main__":
    unittest.main()
