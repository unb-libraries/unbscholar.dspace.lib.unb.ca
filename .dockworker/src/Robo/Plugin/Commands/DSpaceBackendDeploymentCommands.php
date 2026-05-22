<?php

use Dockworker\DockworkerDaemonCommands;

/**
 * Provides commands for building and deploying the DSpace Backend application.
 */
class DSpaceBackendDeployCommands extends DockworkerDaemonCommands
{
    /**
     * Provides error log triggers and exceptions for the DSpace Backend application.
     *
     * @hook on-event dockworker-logs-errors-exceptions
     *
     * @return mixed[]
     *   The error log exceptions.
     */
    public function provideErrorLogConfiguration(): array
    {
        return [
            [],
            array_values(
                [
                    'Lines that also have INFO aren\'t errors' => 'INFO',
                    'configuration is missing in solr-statistics' => 'Statistics are not enabled',
                    'here is already a transaction in progress' => 'not a critical error',
                    'ERROR unknown unknown org.dspace.orcid.model.factory.OrcidFactoryUtils' => 'Known non-critical error for local deployments',
                    'Cannot retrieve ORCID access token' => 'Known non-critical error',
                ]
            ),
        ];
    }
}
