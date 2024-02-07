<?php

namespace Dockworker\Robo\Plugin\Commands;

use Dockworker\Robo\Plugin\Commands\DockworkerDeploymentCommands;

/**
 * Defines commands to interact with a deployed DSpace Frontend application.
 */
class DSpaceBackendDeploymentCommands extends DockworkerDeploymentCommands {

  /**
   * Provides Dspace related new deployed ignored log exceptions.
   *
   * @hook on-event dockworker-deployment-log-error-exceptions
   */
  public function getFrontEndDspaceErrorLogDeploymentExceptions() {
    return [
      'INFO' => 'Lines that also have INFO aren\'t errors',
      'configuration is missing in solr-statistics' => 'Statistics are not enabled',
      'here is already a transaction in progress' => 'not a critical error',
    ];
  }

  /**
   * Provides Dspace related new local ignored log exceptions.
   *
   * @hook on-event dockworker-local-log-error-exceptions
   */
  public function getDSpaceBackendDspaceErrorLogLocalExceptions() {
    return [
      'INFO' => 'Lines that also have INFO aren\'t errors',
      'configuration is missing in solr-statistics' => 'Statistics are not enabled',
      'here is already a transaction in progress' => 'not a critical error',
    ];
  }

}
